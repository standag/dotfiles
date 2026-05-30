---
name: checkout
description: End-of-day activity check-in. Pulls today's Jira activity (via the `jira` skill), GitHub activity (gh CLI), and Claude Code spend (npx ccusage), then prompts the user for meetings, Google Docs, and notes. Writes the combined summary to the terminal and appends to the Obsidian daily note. USE when the user types /checkout or asks for an end-of-day summary.
---

# Checkout Skill

End-of-day activity check-in across Jira, GitHub, and Claude Code spend, with interactive prompts for meetings, docs, and notes. Output is printed to the terminal and appended to the Obsidian daily note.

## Execution Steps

Follow these steps **in order**. Collect all automated data first, then prompt interactively, then assemble and write.

### 1. Jira

Run the Jira activity script and capture stdout as the `## Jira` section:

```fish
python3 ~/.claude/skills/jira/activity.py
```

If `JIRA_TOKEN` is not set, show the error from the script and use `_unavailable — JIRA_TOKEN not set_` as the section body.

### 2. GitHub

Set `TODAY` to today's date (`date +%Y-%m-%d`). Run all three queries and format results as bullet lines `- [repo#N](url) — title (state)`:

```fish
# PRs authored
gh search prs --author=@me --updated=">=$TODAY" --json number,title,url,repository,state,updatedAt --limit 50

# Issues involving me
gh search issues --involves=@me --updated=">=$TODAY" --json number,title,url,repository,state,updatedAt --limit 50

# PRs reviewed by me
gh search prs --reviewed-by=@me --updated=">=$TODAY" --json number,title,url,repository,state,updatedAt --limit 50
```

Deduplicate across queries by URL. Group into sub-sections: **PRs authored**, **Issues**, **PRs reviewed**. Empty sub-section → `_none_`.

### 3. Claude Code spend

```fish
npx -y ccusage@latest daily --since (date +%Y%m%d) --until (date +%Y%m%d)
```

Extract today's row. Report tokens + cost. If no data, use `_none_`.

### 4. Interactive prompts

Ask the user three questions in sequence:

1. **Meetings today** — "Meetings today (one per line, format `Title — Nm` or `Title — Nh Nm`; blank line to finish):"
   - Parse each line to extract duration. Sum total minutes. Format total as `Xh Ym`.
2. **Google Docs** — "Google Docs you worked on (one per line, blank to finish):"
3. **Notes** — "Anything else worth noting (blank to finish):"

### 5. Assemble

First, compose a one-sentence **summary** that captures the day's highlights — meeting load, notable PRs/tickets closed, and Claude Code cost. Keep it under 20 words. Example: "Busy day — 2h 15m of meetings, AI-991 file attachment PR merged, and $8.94 in Claude Code spend."

Then build the full markdown block:

```markdown
# Checkout — HH:MM

> <one-sentence summary>

## Jira
<jira output>

## GitHub
### PRs authored
<items or _none_>
### Issues
<items or _none_>
### PRs reviewed
<items or _none_>

## Claude Code spend
<ccusage row>

## Meetings (total: Xh Ym)
<meeting list>

## Docs
<docs list or _none_>

## Notes
<notes or _none_>
```

`HH:MM` is the current local time at the moment of assembly.

### 6. Write

1. Prepend the summary line to the daily note file as a blockquote on the first line, replacing any existing summary from a prior run today. Specifically: if the file already starts with a `> ` blockquote line, replace that line; otherwise insert it at the top.
2. Append the full assembled block to the end of the daily note file.
3. Print the full assembled block to the terminal, then print the summary sentence on its own line at the very end.
   - If the file does not exist, create it with the summary line first.
   - Use a trailing newline after the block.
   - The timestamped H1 lets multiple `/checkout` runs in one day stack without conflict.

## Daily Note Path

```
~/My Drive/second brain/daily/YYYY-MM-DD.md
```
