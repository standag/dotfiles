---
name: checkin
description: Morning check-in routine. Pulls Jira in-progress and backlog issues, Apple Reminders, and the personal Backlog.md, then helps the user define today's goals and writes a check-in block to the Obsidian daily note. USE THIS SKILL whenever the user types /checkin, asks "what should I work on today", wants a morning standup summary, asks to review their backlog, or starts the day and wants to get oriented. Also trigger for "what's on my plate", "morning check-in", "start my day", or any request to review open tasks and set daily priorities.
---

# Check-in Skill

Morning orientation routine: gather what's open, surface reminders, and help the user commit to today's focus.

## Execution Steps

Run steps 1–4 in parallel (they're independent). Then present, prompt, and write.

### 1. Jira status

```fish
python3 ~/.claude/skills/checkin/scripts/jira_status.py
```

Outputs one section: **In Progress**. If `JIRA_TOKEN` is not set, show the script's error and mark Jira as unavailable.

### 2. Apple Reminders

```fish
remindctl list Work --json
```

Parse the JSON output and format as a bullet list. If the command fails or returns no items, note "_none_".

### 3. Personal Backlog

Read `~/My Drive/second brain/Backlog.md` and include its contents verbatim.

### 4. Previous working day — unfinished items

Find the most recent daily note before today in `~/My Drive/second brain/daily/` (list files, pick the latest `YYYY-MM-DD.md` whose date is before today, read it). Extract any unchecked focus items — lines matching `- [ ]` under a `## Today's focus` section. If none are found or no previous note exists, note "_none_".

### 5. Present the morning picture

Print everything gathered in this format:

```
## Morning Check-in — YYYY-MM-DD

### Unfinished from last working day (YYYY-MM-DD)
<unchecked items, or _none_>

### Jira — In Progress
<items>

### Reminders
<items>

### Personal Backlog
<backlog contents>
```

### 6. Ask for today's focus

After presenting, ask the user one question:

> "What are you focusing on today? (pick from the above or add anything new — one item per line, blank line to finish)"

Listen for their response. Each line is a goal/task for the day.

### 7. Write the daily note

Daily note path:
```
~/My Drive/second brain/daily/YYYY-MM-DD.md
```

Build a check-in block:

```markdown
# Check-in — HH:MM

## Today's focus
- [ ] <goal 1>
- [ ] <goal 2>
...

## Unfinished from last working day (YYYY-MM-DD)
<unchecked items, or _none_>

## Open Jira — In Progress
<items>

## Reminders
<items>

## Personal Backlog
<backlog contents>
```

Write behavior:
- If the daily note doesn't exist, create it with this block as the entire content.
- If it already exists, prepend this block before any existing content (today might be a re-check-in).
- Use `HH:MM` = current local time at write time.

After writing, print: "Check-in written to `daily/YYYY-MM-DD.md`. Good luck today!"
