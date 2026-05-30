---
name: recommit
description: Reorganize the commits on the current PR branch into a smaller set of logical, reviewable commits. Soft-resets back to the merge-base with origin/master, groups the resulting changes, and verifies the final tree is byte-identical to the original HEAD before handing off for force-push. USE THIS SKILL whenever the user asks to "reorganize commits", "squash and resplit", "clean up commit history", "regroup commits for review", "rewrite this PR's commits", or types /recommit. Also trigger when the user complains that their PR has too many commits, that the commit story is messy, that bugfix commits are interleaved with feature commits, or when they want a force-push-ready clean history before review.
---

# recommit — reorganize PR commits into reviewable groups

## What this skill does

Rewrites the commit history of the current branch (from its merge-base with
`origin/master` up to `HEAD`) into a smaller set of logically grouped commits
that a reviewer can read in order. The working tree content is left
completely unchanged — only the commit graph is rewritten.

The skill is built around one hard invariant:

> After the rewrite, `git diff <old-HEAD> HEAD` must be empty.

If that check fails, the skill stops and points the user at the backup
branch it created in Phase 0.

## Why a structured workflow

PR branches accumulate messy history as requirements shift and bugs surface.
Reviewers do their best work on commits of ~200 changed lines and degrade
sharply past 400 (cf. SmartBear/Cisco code review studies, Google's
internal data). A skill that produces a predictable, verified rewrite makes
"clean up the history before review" a routine task instead of a careful
manual rebase.

## When to use

Trigger on phrases listed in the description. Also reasonable to suggest
proactively if the user is about to ask for review on a branch with >5
commits or visibly mixed concerns ("[fix typo]", "[wip]", "[address review]"
all on the same branch).

Do **not** use this skill if:
- The branch has been merged or is being reviewed already (rewriting
  history would break review threads)
- There are merge commits between `merge-base` and `HEAD` — out of scope for v1
- The user wants to interactively rebase for reasons other than regrouping
  (e.g., editing a specific old commit) — use `git rebase -i` directly

## Workflow

The skill runs in five phases. **Report status to the user at the end of
each phase** and wait for approval before Phase 3 (the destructive one).

### Phase 0 — Safety preflight

All read-only except for creating a backup branch.

1. `git status --porcelain` — must be empty. If not, stop and tell the user
   to commit, stash, or discard their working changes first. Untracked files
   are tolerated only if the user confirms they aren't part of the rewrite.
2. `git fetch origin master` — make sure `origin/master` is current.
3. Compute and save these values for later phases:
   - `BASE=$(git merge-base HEAD origin/master)`
   - `OLD_HEAD=$(git rev-parse HEAD)`
   - `OLD_TREE=$(git rev-parse "HEAD^{tree}")`
   - `BRANCH=$(git rev-parse --abbrev-ref HEAD)`
4. Create the backup branch:
   `git branch "recommit-backup/$(date +%Y%m%d-%H%M%S)" HEAD`.
   Print its name to the user verbatim. If anything goes wrong later, the
   recovery command is `git reset --hard <that-branch>`.
5. If `git log --oneline $BASE..HEAD` is empty, there's nothing to do — exit.
6. If the range contains merge commits (`git log --merges $BASE..HEAD` is
   non-empty), stop and tell the user this case isn't supported.

### Phase 1 — Analyze

Gather context for grouping. No mutations.

- `git log --oneline $BASE..HEAD` — current commit narrative
- `git log -n 20 --format='%s' origin/master` — learn the repo's subject
  style. Most repos here use a ticket prefix like `[AI-1019] ...`; match it.
- `git diff --stat $BASE..HEAD` — file-level overview
- For files that look substantial in the stat (>50 changed lines, or
  ambiguous purpose), read the actual diff:
  `git diff $BASE..HEAD -- <file>`

Form a tentative grouping. Heuristics, roughly in priority order:

1. **One concern per commit.** A bugfix and a refactor that happened to land
   together in the original history should be split.
2. **Tests with their code.** Tests for feature X belong in the same commit
   as feature X — that keeps the commit self-validating.
3. **Mechanical changes alone.** Lockfile bumps, generated code regenerations,
   pure renames, and large reformatting passes go in their own commits so
   reviewers can skim past them.
4. **Isolate "different-kind" changes into their own commits.** Each of the
   following categories deserves its own commit (or its own short series) —
   they require a different reviewing mindset than feature code, and mixing
   them inflates cognitive load disproportionately to their line count:
   - **Dependency updates** — `package.json` / `Pipfile` / `go.mod` /
     `Cargo.toml` plus their lockfiles. Reviewer is checking version
     compatibility and security, not logic. One commit per upgrade is best;
     batch only if they're related (e.g., a coordinated framework bump).
   - **Database migrations / schema changes** — migration files, ORM model
     diffs, seed data. Reviewer is checking forward/backward compatibility,
     index impact, and rollout safety. Keep these out of feature commits so
     a revert can target the migration independently.
   - **Configuration / infrastructure** — env var additions, Terraform,
     Helm/k8s manifests, CI workflow edits, Dockerfile changes. Reviewer
     mentally switches into ops mode; don't make them context-switch
     mid-feature.
   - **Public API or contract changes** — OpenAPI/protobuf/GraphQL schema,
     exported type signatures, inter-service contracts. Surface these
     prominently so reviewers can scan the contract before reading the
     implementation.
   - **Generated code** — anything produced by a codegen step (proto stubs,
     OpenAPI clients, prisma client). Usually paired with the contract
     commit that triggered it, but kept separate from hand-written code.
   - **Pure renames and large mechanical refactors** — extract-method,
     rename-symbol, file moves with no logic change. A reviewer can verify
     these with `git log --follow` or `git diff -M`, not by reading lines.
   - **Reformatting / lint autofix** — prettier/black/gofmt sweeps. Always
     alone; otherwise they hide real changes in the noise.
   - **Reverts and rollbacks** — separate, with the original SHA cited in
     the message.
   When in doubt, ask: "would a reviewer approach this with the same
   mindset as the surrounding changes?" If no, split it out — even if it's
   only ~20 lines. Order these commits *first* in the series when feasible
   (deps and migrations before the feature that uses them) so the story
   reads top-to-bottom.
4. **Order builds a story.** Earlier commits should make later commits make
   sense. If commit B depends on a helper introduced in commit A, A goes
   first.
5. **Build-green per commit is nice-to-have, not required.** Under
   soft-reset there's no guarantee each intermediate commit compiles; the
   final tree is what's verified. Note this to the user if it matters.

### Sizing commits

Aim for ~200 changed lines per commit. Treat ~500 as a hard cap unless the
changes form one indivisible logical unit. Exclude lockfiles, generated
code, and pure renames from the count — those don't burden a reviewer.
Prefer fewer coherent commits over many micro-commits; for a typical
1000-line PR, 3–6 commits is the sweet spot. Don't manufacture splits to
hit a number.

### Phase 2 — Propose plan, wait for approval

Present the plan to the user as a table they can scan:

```
Commit 1: [AI-1019] <subject>     ~180 lines  files: src/foo.ts, src/foo.test.ts
Commit 2: [AI-1019] <subject>     ~240 lines  files: src/bar.ts, src/baz.ts
Commit 3: chore: bump lockfile     ~95 lines  files: pnpm-lock.yaml
```

For each commit also draft the full message (subject + optional body) so the
user can read and edit. Use the style observed from `origin/master`'s log.

Ask the user explicitly: "Approve this plan, edit it, or abort?" Do not
proceed to Phase 3 without an unambiguous approval.

If the user wants edits, revise and re-present. Loop until approval.

### Phase 3 — Execute

This is the destructive phase. Everything from here is recoverable only via
the backup branch.

1. `git reset --soft $BASE` — collapse history; all changes are now staged.
2. For each planned commit, in order:
   - `git reset HEAD -- .` — unstage everything (so we can stage only this
     commit's files)
   - For whole-file groupings: `git add -- <files for this commit>`
   - For partial-file groupings: prefer to avoid them. If unavoidable,
     extract the relevant hunks via `git diff` piped into `git apply
     --cached`, or fall back to `git add -p`. Warn the user this path is
     trickier and that intermediate commits may not build.
   - `git commit -m "<message from the approved plan>"` (use a heredoc for
     multi-line messages)
3. After the last planned commit, sanity-check that nothing is left over:
   - `git status --porcelain` should be empty
   - If anything remains, **stop** — the plan didn't cover all changes.
     Tell the user, leave the unstaged content in place, and point at the
     backup branch.

### Phase 4 — Verify (the hard check)

```
NEW_TREE=$(git rev-parse "HEAD^{tree}")
test "$OLD_TREE" = "$NEW_TREE"    # must succeed
git diff "$OLD_HEAD" HEAD          # must print nothing
```

Both checks must pass. If either fails:
- Do **not** delete the backup branch.
- Show the user the output of `git diff $OLD_HEAD HEAD` so they can see
  what diverged.
- Offer the recovery command: `git reset --hard <backup-branch>`.

### Phase 5 — Hand off

If verification passes:
- Print the new commit list: `git log --oneline $BASE..HEAD`
- Remind the user of the backup branch name (they can delete it once
  they're satisfied, e.g., in a few days)
- Tell them the push command but **do not run it** — pushing is the user's
  decision. Suggest `git push --force-with-lease` over `--force` so a
  concurrent push from another machine isn't silently overwritten.

## Failure modes — quick reference

| Situation                          | Action                                                  |
|------------------------------------|---------------------------------------------------------|
| Dirty working tree                 | Stop in Phase 0; ask user to clean up first             |
| No commits ahead of merge-base     | Exit in Phase 0; nothing to do                          |
| Merge commits in range             | Stop in Phase 0; out of scope                           |
| Plan doesn't cover all changes     | Stop in Phase 3 after last commit; point to backup      |
| Tree mismatch in Phase 4           | Stop, show diff, offer `git reset --hard <backup>`      |
| User aborts during Phase 2        | No mutations happened yet (besides the backup branch); safe to walk away |

## Notes for the running agent

- Run git commands directly via Bash — no bundled scripts.
- Treat the backup branch as sacred until Phase 5 succeeds. Never delete
  it on the user's behalf.
- Don't push. The skill ends at "here's the command you'd run."
- If the user has CLAUDE.md guidance about commit message format (ticket
  prefixes, Co-Authored-By trailers, etc.), respect it — read recent
  commits to confirm the convention before drafting messages.
