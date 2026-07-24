#!/usr/bin/env bash
# Claude Code statusline: model | context bar | session cost | usage limits | project
set -euo pipefail

input=$(cat)

# renders a 10-segment colored block bar for a 0-100 percentage
render_bar() {
  local pct=$1
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0

  local filled=$(( pct / 10 ))
  local empty=$(( 10 - filled ))
  local bar
  bar=$(printf '%0.s█' $(seq 1 $filled) 2>/dev/null)
  bar+=$(printf '%0.s░' $(seq 1 $empty) 2>/dev/null)

  local color
  if [ "$pct" -ge 80 ]; then color="\033[31m"   # red
  elif [ "$pct" -ge 50 ]; then color="\033[33m" # yellow
  else color="\033[32m"; fi                     # green

  printf '%b%s %s%%\033[0m' "$color" "$bar" "$pct"
}

# formats a token count as e.g. 47k or 1.2M
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n / 1000000 }'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%dk", n / 1000 }'
  else
    printf '%d' "$n"
  fi
}

# formats seconds until a given ISO8601 timestamp as e.g. 2h20m
format_countdown() {
  local target_epoch=$1
  local now_epoch=$2
  local diff=$(( target_epoch - now_epoch ))
  [ "$diff" -lt 0 ] && diff=0
  local h=$(( diff / 3600 ))
  local m=$(( (diff % 3600) / 60 ))
  printf '%dh%02dm' "$h" "$m"
}

# ---- model ----
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')

# ---- project (repo name or folder name) + git branch/PR ----
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
git_part=""
if repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
  project=$(basename "$repo_root")
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

  if [ -n "$branch" ]; then
    git_part="🌿 $branch"

    if command -v gh >/dev/null 2>&1; then
      pr_cache="$HOME/.claude/.pr_cache_$(echo "$repo_root-$branch" | shasum | cut -c1-12).json"
      now_pr=$(date +%s)
      use_pr_cache=false
      if [ -f "$pr_cache" ]; then
        cached_at=$(jq -r '.cached_at_epoch // 0' "$pr_cache" 2>/dev/null || echo 0)
        age=$(( now_pr - cached_at ))
        [ "$age" -lt 60 ] && use_pr_cache=true
      fi

      if [ "$use_pr_cache" = false ]; then
        pr_json=$(gh pr view --json number,state 2>/dev/null || echo '{}')
        jq -n --argjson now "$now_pr" --argjson pr "$pr_json" \
          '{cached_at_epoch: $now, number: ($pr.number // null), state: ($pr.state // null)}' \
          > "$pr_cache" 2>/dev/null || true
      fi

      pr_number=$(jq -r '.number // empty' "$pr_cache" 2>/dev/null || true)
      pr_state=$(jq -r '.state // empty' "$pr_cache" 2>/dev/null || true)
      if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
        git_part="$git_part #$pr_number ($pr_state)"
      fi
    fi
  fi
else
  project=$(basename "$cwd")
fi

# ---- context window usage ----
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
context_part=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  usage=$(tail -r "$transcript" 2>/dev/null | grep -m1 '"usage"' || true)
  if [ -n "$usage" ]; then
    tokens=$(echo "$usage" | jq -r '
      (.message.usage.input_tokens // 0)
      + (.message.usage.cache_creation_input_tokens // 0)
      + (.message.usage.cache_read_input_tokens // 0)
    ')
    limit=200000
    pct=$(( tokens * 100 / limit ))
    [ "$pct" -gt 100 ] && pct=100

    context_part="$(render_bar "$pct") $(format_tokens "$tokens")/$(format_tokens "$limit")"
  fi
fi

# ---- session cost ----
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_fmt=$(printf '$%.2f' "$cost")

# ---- usage limits (skip on work account) ----
limits_part=""
if [ -z "${CLAUDE_WORK_ACCOUNT:-}" ]; then
  cache_file="$HOME/.claude/.usage_cache.json"
  now=$(date +%s)
  use_cache=false
  if [ -f "$cache_file" ]; then
    cached_at=$(jq -r '.cached_at_epoch // 0' "$cache_file" 2>/dev/null || echo 0)
    age=$(( now - cached_at ))
    [ "$age" -lt 60 ] && use_cache=true
  fi

  if [ "$use_cache" = false ]; then
    token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
      | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)
    if [ -n "$token" ]; then
      fresh=$(curl -s -m 3 "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null || echo '{}')
      five_hour=$(echo "$fresh" | jq -r '.five_hour.utilization // empty' 2>/dev/null || true)
      seven_day=$(echo "$fresh" | jq -r '.seven_day.utilization // empty' 2>/dev/null || true)
      five_resets=$(echo "$fresh" | jq -r '.five_hour.resets_at // empty' 2>/dev/null || true)
      seven_resets=$(echo "$fresh" | jq -r '.seven_day.resets_at // empty' 2>/dev/null || true)
      jq -n --arg five "${five_hour:-null}" --arg seven "${seven_day:-null}" \
        --arg five_resets "${five_resets:-null}" --arg seven_resets "${seven_resets:-null}" \
        --argjson now "$now" \
        '{cached_at_epoch: $now,
          five_hour: ($five | tonumber? // null), seven_day: ($seven | tonumber? // null),
          five_resets_at: $five_resets, seven_resets_at: $seven_resets}' \
        > "$cache_file" 2>/dev/null || true
    fi
  fi

  five_hour=$(jq -r '.five_hour // empty' "$cache_file" 2>/dev/null || true)
  seven_day=$(jq -r '.seven_day // empty' "$cache_file" 2>/dev/null || true)
  five_resets_at=$(jq -r '.five_resets_at // empty' "$cache_file" 2>/dev/null || true)
  seven_resets_at=$(jq -r '.seven_resets_at // empty' "$cache_file" 2>/dev/null || true)
  if [ -n "$five_hour" ] && [ "$five_hour" != "null" ]; then
    five_pct=$(printf '%.0f' "$five_hour")
    seven_pct=$(printf '%.0f' "${seven_day:-0}")
    limits_part="5h $(render_bar "$five_pct")"
    if [ -n "$five_resets_at" ] && [ "$five_resets_at" != "null" ]; then
      five_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${five_resets_at%%.*}" +%s 2>/dev/null || true)
      [ -n "$five_epoch" ] && limits_part="$limits_part (resets $(format_countdown "$five_epoch" "$now"))"
    fi
    limits_part="$limits_part · 7d $(render_bar "$seven_pct")"
    if [ -n "$seven_resets_at" ] && [ "$seven_resets_at" != "null" ]; then
      seven_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${seven_resets_at%%.*}" +%s 2>/dev/null || true)
      [ -n "$seven_epoch" ] && limits_part="$limits_part (resets $(format_countdown "$seven_epoch" "$now"))"
    fi
  fi
fi

# ---- assemble ----
parts=("🤖 $model" "📁 $project")
[ -n "$git_part" ] && parts+=("$git_part")
[ -n "$context_part" ] && parts+=("$context_part")
parts+=("💰 $cost_fmt")
[ -n "$limits_part" ] && parts+=("⏱ $limits_part")

out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$p"; else out="$out | $p"; fi
done
printf '%b\n' "$out"
