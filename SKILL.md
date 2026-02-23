---
name: brag
description: "Generate developer accomplishment report from GitHub PRs, git commits, Claude Code sessions, Asana tasks, Slack activity, Sentry issues, and PR review depth. Supports narrative, technical log, and product announcement modes. Use for standups, check-ins, brag docs, promo packets, or product updates."
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash(gh *), Bash(git log *), Bash(git config *), Bash(date *), Read, Write, Grep, Glob, ToolSearch, AskUserQuestion
argument-hint: "[setup | today | yesterday | week | last_week | 7d | 14d | YYYY-MM-DD..YYYY-MM-DD] [--log | --announce] [--short] [--slack #channel]"
---

# /brag — Developer Accomplishment Report

Generate a work accomplishment report by aggregating data from multiple sources and presenting it with impact framing.

## Injected Context

- Current date: !`date +%Y-%m-%d`
- Git author: !`git config user.name 2>/dev/null || echo "unknown"`
- GitHub user: !`gh api user --jq .login 2>/dev/null || echo "not authenticated"`
- Repo URL: !`gh repo view --json url -q .url 2>/dev/null || echo "unknown"`

## Step 0: Help / No Arguments

If `$ARGUMENTS` is empty, or is `help`, `--help`, or `?`, display this usage guide and stop — do NOT generate a report:

```
/brag — Developer Accomplishment Report

Usage: /brag <time range> [--log | --announce] [--short] [--slack #channel]
       /brag setup          Configure data sources and preferences

Time ranges:
  today              Today's activity (default if omitted with a mode flag)
  yesterday          Yesterday's activity
  week               Monday of this week to today
  last_week          Last Monday through last Sunday
  7d, 14d            Last N days
  2026-02-01..02-14  Custom date range
  "last two weeks"   Natural language also works

Output modes:
  (default)          Narrative — grouped by impact themes (Shipped, Kept the Lights On, etc.)
  --log              Technical changelog — organized by data source (PRs, commits, tasks)
  --announce         Product announcement — product-updates format for stakeholders

Length:
  (default)          Detailed report
  --short            Condensed version (~15-25 lines)

Slack:
  --slack #channel   Post report to a Slack channel
  --slack @user      Send as DM (use "for myself" to DM yourself)

Setup:
  /brag setup                            Configure data sources and preferences

Examples:
  /brag last_week                        Narrative report for last week
  /brag 14d --short                      Quick summary of last 2 weeks
  /brag last_week --log                  Technical changelog
  /brag last_week --announce             Product update draft
  /brag week --short --slack #standup    Short report posted to Slack

Data sources: GitHub PRs, git commits, Asana tasks, Claude Code sessions,
              Slack activity, Sentry issues, PR review depth
```

## Step 0.5: Setup Flow (`/brag setup`)

If `$ARGUMENTS` is `setup`, run this interactive configuration flow instead of generating a report.

### Phase 1: Auto-Detect Sources (run ALL checks in parallel)

1. **GitHub**: `gh auth status`
2. **Git**: use the injected Git author above
3. **Asana MCP**: ToolSearch for "asana" — if available, use `mcp__asana__asana_list_workspaces`
4. **Slack MCP**: ToolSearch for "slack" — look for logged-in user's ID in tool descriptions
5. **Sentry MCP**: ToolSearch for "sentry" — if available, use `mcp__sentry__find_organizations` and `mcp__sentry__find_projects`
6. **Claude Sessions**: check if `~/.claude/history.jsonl` exists

### Phase 2: Display Status and Ask Questions

Display a status table:

```
/brag setup — Source Configuration

| Source           | Status      | Details                    |
|------------------|-------------|----------------------------|
| GitHub           | ✓ Ready     | Authenticated as @username |
| Git              | ✓ Ready     | Author: "Your Name"        |
| Asana            | ✓ Available | Workspace: "Company"       |
| Slack            | ✓ Available | User: U12345               |
| Sentry           | ✓ Available | Org: org-slug              |
| Claude Sessions  | ✓ Ready     | history.jsonl found        |
```

Use `✓ Ready` for sources that work out of the box, `✓ Available` for detected MCP sources, `✗ Not found` for unavailable sources.

Then ask source-specific questions using AskUserQuestion:
1. **Slack channels** (if available): "Which Slack channel do you use for product updates?"
2. **Sentry project** (if multiple): "Which Sentry project should /brag monitor?"
3. **Default preferences**: mode (Narrative/Log/Announce) and time range (last_week/week/7d/14d)

### Phase 3: Write Config

Determine the skill directory (resolve symlinks). Write `config.json` — see [config.json.example](config.json.example) for the schema.

Set `"enabled": false` for undetected sources. After writing, display a summary and stop — do NOT proceed to generate a report.

## Step 1: Parse Arguments and Compute Date Range

### Load Config (if exists)

Check for `config.json` in this skill's directory (resolve symlinks). If it exists:
- Use `defaults.time_range` when no time range in `$ARGUMENTS`
- Use `defaults.mode` when no mode flag in `$ARGUMENTS`
- Use `defaults.short` when no `--short` flag in `$ARGUMENTS`

**Important**: If config provides defaults, do NOT show help text when `$ARGUMENTS` is empty — use the defaults and generate a report. Help is only for explicit `help`, `--help`, or `?`.

### Parse Flags

Extract flags from `$ARGUMENTS` (remove each after extracting):
- `--slack #channel-name` or `--slack @user` → Slack target
- `--log` → LOG mode | `--announce` → ANNOUNCE mode | no flag → NARRATIVE mode
- `--short` → SHORT length
- Natural language: "short"/"brief" → SHORT; "changelog"/"technical" → LOG; "announce"/"product update" → ANNOUNCE

### Compute Date Range

For date arithmetic details, see [reference/date-parsing.md](reference/date-parsing.md).

Compute START_DATE and END_DATE as `YYYY-MM-DD` strings using macOS `date -v`.

## Step 2: Collect Data (All Sources in Parallel)

Use parallel tool calls for all sources simultaneously. Each source is independent — if one fails, continue with the others.

For detailed collection instructions per source, see [reference/data-sources.md](reference/data-sources.md).

**Sources to collect (all in parallel):**

1. **GitHub PRs** — authored and reviewed PRs via `gh pr list` (use injected Repo URL for commit links)
2. **PR Review Depth** — classify review quality (NARRATIVE and LOG modes only)
3. **Git Commits** — `git log` using injected Git author
4. **Claude Code Sessions** — read `~/.claude/history.jsonl`, deduplicate by sessionId
5. **Asana Tasks** (MCP, optional) — completed tasks in date range
6. **Slack Activity** (MCP, optional) — filter by signal level per mode
7. **Sentry Issues** (MCP, optional) — resolved issues with impact numbers

### Config-Aware Optimization

If config exists: skip disabled sources, use stored values (author name, Slack user ID, workspace GID, org/project slugs), skip ToolSearch for known MCP sources.

## Step 3: Auto-Clustering (NARRATIVE and ANNOUNCE modes only)

Skip this step for LOG mode. For detailed clustering rules, see [reference/clustering.md](reference/clustering.md).

Cluster related items into deliverables, then categorize each into one of four themes:
- **Shipped**: features that went to production
- **Kept the Lights On**: on-call, hotfixes, Sentry issues, incidents
- **Invested in the Future**: tooling, refactors, DX, docs
- **Helped the Team**: reviews, unblocking, knowledge sharing

## Step 4: Generate Report

Use the appropriate template based on mode and length:
- **NARRATIVE** (default): see [templates/narrative.md](templates/narrative.md)
- **LOG** (`--log`): see [templates/log.md](templates/log.md)
- **ANNOUNCE** (`--announce`): see [templates/announce.md](templates/announce.md)

## Step 5: Slack Posting (Optional)

Only if `--slack` flag is present or user explicitly asks:

1. Use ToolSearch for "slack send"
2. Use `mcp__claude_ai_Slack__slack_send_message` to post
3. **Format for Slack** (Slack markdown, not GitHub markdown):
   - `*bold*` not `**bold**`
   - Bullet points with `•`
   - Plain URLs (Slack auto-unfurls GitHub and Asana links)
   - For `--announce`, use the emoji-header format from the template
4. For `--announce` with `--slack`, show draft first and ask for confirmation
5. If Slack MCP unavailable, show report in terminal only

## Report Guidelines (All Modes)

- **Always include links** — PRs, Asana tasks, Sentry issues, commits. Non-negotiable.
  - PRs: `[#32517](url)` | Asana: `[Task name](permalink_url)` | Commits: `[hash](repo_url/commit/full_hash)` | Sentry: `[Issue title](url)`
- **Omit empty sections** — never show a section header with zero items
- **Single day reports** use "Work Report: {DATE}" instead of a range
- **Impact framing** (NARRATIVE/ANNOUNCE): describe *what changed for users/the team*, not what files were modified
- **On-call collapsing**: never list identical tasks individually — collapse with count and one example link

## Error Handling

- Each data source is independent — if one fails, continue with the others
- If ALL sources return empty: "No activity found for {date range}. Check that you're in the right git repo and `gh` is authenticated."
- Never show raw error output — fail silently per source
- If `gh` auth fails, suggest `gh auth login`
- For `--announce` with no features: "No features to announce for this period. Try `--log` or default mode to see all activity."
