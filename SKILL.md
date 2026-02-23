---
name: brag
description: "Generate developer accomplishment report from GitHub PRs, git commits, Claude Code sessions, Asana tasks, Slack activity, Sentry issues, and PR review depth. Supports narrative, technical log, and product announcement modes. Track long-term impact and developer domain expertise. Use for standups, check-ins, brag docs, promo packets, or product updates."
user-invocable: true
allowed-tools: Bash, Read, Write, Grep, Glob, ToolSearch, AskUserQuestion
argument-hint: "[setup | impact | impact add | value | value add | today | yesterday | week | last_week | 7d | 14d | YYYY-MM-DD..YYYY-MM-DD] [--log | --announce] [--short] [--slack #channel]"
author: "Vinicius Kammradt"
author-url: "https://github.com/kammradt"
---

# /brag — Developer Accomplishment Report

Generate a work accomplishment report by aggregating data from multiple sources and presenting it with impact framing.

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

Run these checks simultaneously using parallel tool calls:

1. **GitHub**: `gh auth status` — check if `gh` is authenticated
2. **Git**: `git config user.name` — get the configured author name
3. **Asana MCP**: Use ToolSearch to search for "asana" — check if Asana MCP tools are available. If available, use `mcp__asana__asana_list_workspaces` to get workspace GIDs.
4. **Slack MCP**: Use ToolSearch to search for "slack" — check if Slack MCP tools are available. If available, look for the logged-in user's ID in tool descriptions.
5. **Sentry MCP**: Use ToolSearch to search for "sentry" — check if Sentry MCP tools are available. If available, use `mcp__sentry__find_organizations` and `mcp__sentry__find_projects` to get org/project slugs.
6. **Claude Sessions**: Check if `~/.claude/history.jsonl` exists

### Phase 2: Display Status and Ask Questions

Display a status table showing what was detected:

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

Use `✓ Ready` for sources that work out of the box, `✓ Available` for MCP sources detected, `✗ Not found` for unavailable sources.

Then ask source-specific questions using AskUserQuestion:

1. **Slack channels** (if Slack available): "Which Slack channel do you use for product updates?" — offer detected channels or let user type one
2. **Sentry project** (if Sentry available and multiple projects found): "Which Sentry project should /brag monitor?"
3. **Default preferences**: "What should be the default output mode and time range?"
   - Mode options: Narrative (recommended), Technical Log, Product Announcement
   - Time range options: last_week (recommended), week, 7d, 14d

### Phase 3: Write Config

Write the config file to `~/.claude/skills/brag/config.json` (or the skill's directory if symlinked):

Determine the skill directory:
```bash
SKILL_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$HOME/.claude/skills/brag/SKILL.md")")"
```

Since we're running inside Claude Code, use the skill's own directory. Check if `~/.claude/skills/brag` is a symlink:
- If symlink: write config to the symlink target directory
- If regular directory: write config to `~/.claude/skills/brag/`

Write `config.json` with the structure:
```json
{
  "version": 1,
  "defaults": {
    "mode": "narrative",
    "time_range": "last_week",
    "short": false
  },
  "sources": {
    "github": { "enabled": true, "verified": true },
    "git": { "enabled": true, "author_name": "detected name" },
    "asana": { "enabled": true, "workspace_gid": "detected GID" },
    "slack": {
      "enabled": true,
      "user_id": "detected ID",
      "channels": { "product_updates": "#channel-name" }
    },
    "sentry": { "enabled": true, "organization": "org-slug", "project": "project-slug" },
    "claude_sessions": { "enabled": true }
  }
}
```

Set `"enabled": false` for any source that wasn't detected. Omit source-specific fields (like `workspace_gid`) for disabled sources.

After writing, display a summary:

```
Config saved to ~/.claude/skills/brag/config.json

Enabled sources: GitHub, Git, Asana, Slack, Sentry, Claude Sessions
Default mode: narrative
Default time range: last_week

Run /brag last_week to try it out!
```

**Then stop — do NOT proceed to generate a report.**

## Step 1: Parse Arguments and Compute Date Range

### Load Config (if exists)

Before parsing arguments, check for a config file:

```bash
CONFIG_PATH="$HOME/.claude/skills/brag/config.json"
# If the skill dir is a symlink, resolve it
if [[ -L "$HOME/.claude/skills/brag" ]]; then
  CONFIG_PATH="$(readlink "$HOME/.claude/skills/brag")/config.json"
fi
```

Read the config file using the Read tool. If it exists, use its `defaults` when no arguments are provided:
- If `$ARGUMENTS` has no time range and config has `defaults.time_range` → use that as the time range
- If `$ARGUMENTS` has no mode flag and config has `defaults.mode` → use that mode (`"narrative"` = default, `"log"` = LOG, `"announce"` = ANNOUNCE)
- If `$ARGUMENTS` has no `--short` flag and config has `defaults.short: true` → use SHORT length

**Important**: If config exists and provides defaults, do NOT show help text when `$ARGUMENTS` is empty — instead, use the defaults and proceed to generate a report. Help text is only shown for explicit `help`, `--help`, or `?`.

Parse `$ARGUMENTS` to determine the time range, output mode, and optional Slack target.

**Extract flags first** (remove each from the time argument after extracting):
- `--slack #channel-name` or `--slack @user` → Slack target
- `--log` → LOG mode (technical changelog)
- `--announce` → ANNOUNCE mode (product announcement)
- `--short` → SHORT length
- No mode flag → NARRATIVE mode (default)
- Natural language: "short"/"brief" → SHORT length; "changelog"/"technical" → LOG mode; "announce"/"product update" → ANNOUNCE mode

**Time range parsing** (use macOS `date -v` for arithmetic):

| Argument | START_DATE | END_DATE |
|---|---|---|
| Empty / `today` | today | today |
| `yesterday` | yesterday | yesterday |
| `week` / `this_week` | Monday of current week | today |
| `last_week` | Monday of prev week | Sunday of prev week |
| `Nd` (e.g. `7d`, `14d`) | N days ago | today |
| `YYYY-MM-DD..YYYY-MM-DD` | first date | second date |

Also accept natural language like "last two weeks" = 14d, "this month" = 1st of month to today.

Compute START_DATE and END_DATE as `YYYY-MM-DD` strings using Bash:

```bash
# today
START=$(date +%Y-%m-%d)
END=$(date +%Y-%m-%d)

# yesterday
START=$(date -v-1d +%Y-%m-%d)
END=$START

# Nd (extract N from argument)
START=$(date -v-${N}d +%Y-%m-%d)
END=$(date +%Y-%m-%d)

# this_week (Monday)
DOW=$(date +%u)  # 1=Mon, 7=Sun
START=$(date -v-$((DOW - 1))d +%Y-%m-%d)
END=$(date +%Y-%m-%d)

# last_week
DOW=$(date +%u)
START=$(date -v-$((DOW + 6))d +%Y-%m-%d)
END=$(date -v-${DOW}d +%Y-%m-%d)

# explicit range: split on ".."
START=${ARG%%".."*}
END=${ARG##*".."}
```

## Step 2: Collect Data (Run All Sources in Parallel)

Use parallel Bash calls, MCP tools, and Glob/Read for all sources simultaneously. Do NOT run them sequentially. Each source is independent — if one fails, continue with the others.

### Config-Aware Collection

If a `config.json` was loaded in Step 1, use it to optimize data collection:
- **Skip disabled sources**: If `sources.{name}.enabled` is `false`, skip that source entirely — don't even attempt detection
- **Use stored values**: Use `sources.git.author_name` for git log `--author`, `sources.slack.user_id` for Slack searches, `sources.slack.channels.product_updates` for announce mode, `sources.sentry.organization` and `sources.sentry.project` for Sentry queries, `sources.asana.workspace_gid` for Asana searches
- **Skip ToolSearch for known MCP sources**: If config says a source is enabled and verified, use the MCP tools directly instead of searching for them first

If no config exists, fall back to the auto-detect behavior below (search for tools, infer values).

### Source 1: GitHub PRs and Repo URL (Bash)

Run three commands in parallel:

**PRs authored:**
```bash
gh pr list --search "author:@me created:>=${START} created:<=${END}" --state=all --limit 100 --json number,title,state,url,createdAt,mergedAt,additions,deletions,reviewDecision
```

**PRs reviewed:**
```bash
gh pr list --search "reviewed-by:@me -author:@me created:>=${START}" --state=all --limit 100 --json number,title,state,url
```

**Repo base URL** (needed for commit links):
```bash
gh repo view --json url -q .url
```
This gives you the base like `https://github.com/org/repo` — append `/commit/{hash}` for commit links.

If `gh` is not authenticated or fails, skip this source silently.

### Source 2: PR Review Depth (Bash, for NARRATIVE and LOG modes)

For each PR you reviewed, fetch your review details to classify review quality:

```bash
GH_USER=$(gh api user --jq .login)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq "[.[] | select(.user.login == \"${GH_USER}\")] | length"
```

Classify each reviewed PR as:
- **Approved (no comments)** — quick approval
- **Approved with feedback** — substantive review with comments
- **Changes requested** — caught issues that needed fixing

Use this to enrich the "Helped the Team" section in NARRATIVE mode or the reviews table in LOG mode.

### Source 3: Git Commits (Bash)

```bash
git log --author="$(git config user.name)" --since="${START}" --until="${END} 23:59:59" --format="%h|%H|%ad|%s" --date=short --no-merges --all
```

The format includes both short hash (`%h`) for display and full hash (`%H`) for commit URL links.

If config has `sources.git.author_name`, use that instead of `$(git config user.name)`.

If not in a git repo, skip silently.

### Source 4: Claude Code Sessions (Glob + Read)

Find session files that overlap with the date range:

1. **Read `~/.claude/history.jsonl`** — each line is a JSON object with `sessionId`, `timestamp` (Unix ms), `project`, `display` (first user message). Filter entries where timestamp falls within START_DATE..END_DATE.

2. **Deduplicate by sessionId**, keeping the first and last timestamps per session. Extract:
   - **Project**: from directory path (last segment)
   - **Task summary**: the first `display` value (truncate to ~80 chars)
   - **Message count**: number of entries per session
   - **Duration**: difference between first and last timestamps

Limit to 20 most recent sessions to keep report manageable. This source is primarily used in LOG mode and as context for NARRATIVE mode clustering.

### Source 5: Asana Tasks (MCP, optional)

1. First, use ToolSearch to check if Asana MCP tools are available (search for "asana"). If config has `sources.asana.enabled: true`, skip the ToolSearch and use MCP tools directly.
2. If available, use `mcp__asana__asana_search_tasks` to find tasks (use `sources.asana.workspace_gid` from config if available):
   - Search for tasks assigned to "me" completed in the date range
   - Use `completed_on.after` = START_DATE and `completed_on.before` = day after END_DATE
   - Include `opt_fields`: `name,completed_at,memberships.project.name,permalink_url`
3. If Asana MCP is not configured or the call fails, skip this source entirely — do NOT show an error

### Source 6: Slack Activity (MCP, optional)

1. Use ToolSearch to check if Slack MCP tools are available (search for "slack search")
2. If available, get the current user's Slack ID. If config has `sources.slack.user_id`, use that directly. Otherwise, the Slack MCP tools typically expose the logged-in user's ID in their tool descriptions (look for "Current logged in user's user_id is ..."). Use that ID. Then search for your own messages:

```
slack_search_public(query="from:<@{YOUR_SLACK_USER_ID}> after:{START_UNIX} before:{END_UNIX}", sort="timestamp", limit=20)
```

3. **Filter by signal level:**

   **High-signal (always include):**
   - Messages in the product updates channel (use `sources.slack.channels.product_updates` from config if available) — announcements you already wrote
   - Messages with 3+ reactions — team found it valuable
   - Messages containing Loom links (`loom.com/share`)
   - Thread-starting messages in engineering channels

   **Medium-signal (include in NARRATIVE mode):**
   - Messages in on-call or incident channels
   - Messages sharing PR links or deployment notifications

   **Low-signal (always skip):**
   - Replies under 20 characters ("ok", "thanks", "sounds good")
   - Messages in social/random/off-topic channels

4. If Slack MCP is not available, skip silently

**Per-mode usage:**
- `--log`: not used
- NARRATIVE: enriches "Kept the Lights On" (on-call messages) and "Helped the Team" (unblocking threads). Counts high-reaction messages.
- `--announce`: pulls existing the product updates channel posts verbatim. Identifies shipped work that hasn't been announced yet.

### Source 7: Sentry Issues (MCP, optional)

1. Use ToolSearch to check if Sentry MCP tools are available (search for "sentry"). If config has `sources.sentry.enabled: true`, skip the ToolSearch and use MCP tools directly.
2. If available, search for issues you resolved in the date range using `mcp__sentry__search_issues`. Use `sources.sentry.organization` and `sources.sentry.project` from config if available.
3. For each resolved issue, extract:
   - Issue title and URL
   - Times seen / users affected (impact numbers)
   - When it was first seen vs resolved (resolution speed)
4. If Sentry MCP is not available, skip silently

This data enriches impact framing: "Fixed ingestion failure affecting 12 workflows" is much stronger than "merged PR #32380".

## Step 3: Auto-Clustering

Before generating the report, **cluster related items into deliverables**. This is critical for NARRATIVE and ANNOUNCE modes. Skip this step for LOG mode.

**Clustering rules:**
1. **By ticket prefix**: items sharing an Asana ticket or JIRA-style prefix (e.g. `EGL-3604`, `EGL-3601`) are likely the same initiative
2. **By branch name**: commits and PRs on the same branch belong together
3. **By keyword overlap**: PR titles, commit subjects, and Asana task names with significant word overlap (ignoring common words like "fix", "update", "add")
4. **Collapse repetitive items**: multiple identical Asana tasks (e.g. 8x "Delete duplicated profile") become one line with a count

**Each cluster becomes a deliverable with:**
- A short descriptive title (not a PR title — a human summary)
- The list of associated PRs, commits, Asana tasks, and Sentry issues (with links)
- An impact statement: what changed and why it matters

**Categorize each deliverable into one of four themes:**
- **Shipped**: merged PRs linked to feature Asana tasks (not from "On-call" projects). These are new capabilities that went to production.
- **Kept the Lights On**: items from Asana "On-call" projects, hotfixes, reverts, Sentry issues, incident-channel Slack messages. Operational work that kept things running.
- **Invested in the Future**: tooling, documentation, skills, refactors, DX improvements, test improvements. Work that pays off later.
- **Helped the Team**: PRs reviewed (with depth classification), cross-pod Asana tasks, Slack threads where you unblocked others. Multiplier work.

**Heuristics for categorization:**
- Asana project name contains "On-call" → Kept the Lights On
- PR title starts with "Revert" or "hotfix" → Kept the Lights On
- PR title contains "refactor", "docs", "skill", "tooling", "DX" → Invested in the Future
- Sentry-linked PRs → Kept the Lights On
- PRs you reviewed (not authored) → Helped the Team
- Everything else → Shipped

## Step 4: Generate Report

### MODE 1: NARRATIVE (default)

The narrative report organizes work by theme, not by data source. Each section tells a story.

#### NARRATIVE DETAILED

```markdown
# Work Report: {START_DATE} to {END_DATE}

## Summary
{3-4 sentence first-person narrative. Lead with the most impactful deliverable. Identify themes across all work. Mention key numbers. This should read like the opening paragraph of a promo packet entry.}

## Shipped
{Deliverables that went to production and deliver value.}

### {Deliverable title}
{1-2 sentence description of what was built and why it matters — not what files changed, but what capability now exists.}
- {[PR link](url)} {[PR link](url)} {[Asana task link](url)}

### {Deliverable title}
...

## Kept the Lights On
{On-call, incident response, operational fixes. Collapse into a narrative, not individual items.}

{Summary paragraph: "Handled N on-call tasks over the period including [types of issues]. Resolved [Sentry issue] affecting N users within N hours. Key incidents: [brief list]."}
- {[Sentry issue](url)} — {impact: N users affected, resolved in N hours}
- {[PR](url)} — {one-liner}
- {N}x {repetitive task name} ({[example link](url)})

## Invested in the Future
{Tooling, skills, infra, DX improvements.}

### {Deliverable title}
{Description + why it matters for the team long-term}
- {links}

## Helped the Team
{Reviews, unblocking, knowledge sharing.}

Reviewed **{N}** PRs — **{N}** with substantive feedback, **{N}** with changes requested.
{Highlight 1-2 notable reviews where you caught something important.}
- {[PR](url)} — {what you caught or suggested}

{If Slack data available: "Unblocked N teammates in Slack threads, responded to N on-call questions."}
```

**Omit any section that has zero items.**

#### NARRATIVE SHORT

```markdown
# Work Report: {START_DATE} to {END_DATE}

## Summary
{3-4 sentence narrative — same quality as detailed}

## Highlights
- {Most impactful deliverable, framed with impact, with link}
- {Second most impactful, with link}
- {Third, with link}
- {On-call/operational highlight if significant}
- {Team contribution highlight}

## By the Numbers
- **{N}** PRs merged | **{N}** PRs reviewed ({N} with substantive feedback)
- **{N}** commits across {N} days
- **{N}** Asana tasks completed | **{N}** Sentry issues resolved
- **{N}** Claude Code sessions
```

Total output: ~15-25 lines max.

### MODE 2: LOG (`--log`)

The technical log organizes by data source. No clustering, no impact framing. Just the raw data with links. This is the original format.

#### LOG DETAILED

```markdown
# Work Report: {START_DATE} to {END_DATE}

## Summary
{2-3 sentence factual summary with numbers.}

## Pull Requests

### Authored ({count})
| PR | Title | Status | +/- |
|----|-------|--------|-----|
| [#{number}]({url}) | {title} | {MERGED/OPEN/CLOSED} | +{additions}/-{deletions} |

### Reviewed ({count})
| PR | Title | Status | Review |
|----|-------|--------|--------|
| [#{number}]({url}) | {title} | {state} | {Approved/Feedback/Changes requested} |

## Commits ({count})

### {date}
- [`{hash}`]({repo_url}/commit/{full_hash}) {subject}

## Asana Tasks Completed ({count})
- [x] [{task name}]({asana_permalink_url}) ({project name})

## Sentry Issues Resolved ({count})
- [{issue title}]({sentry_url}) — {times_seen} occurrences, {users_affected} users

## Claude Code Sessions ({count})
- **{branch or project}** — {task summary} ({N edits, N commands})
```

#### LOG SHORT

```markdown
# Work Report: {START_DATE} to {END_DATE}

## Summary
{2-3 sentence factual summary}

## Highlights
- {Top PR with link}
- {Top PR with link}
- {Top PR with link}

## By the Numbers
- **{N}** PRs merged ({links to top 3}) | **{N}** PRs reviewed
- **{N}** commits across {N} days
- **{N}** Asana tasks completed
- **{N}** Claude Code sessions
```

### MODE 3: ANNOUNCE (`--announce`)

Generates stakeholder-facing product announcements following the the product updates channel channel convention. Only includes **shipped features** — no on-call, no reviews, no operational work.

**Pre-check**: If Slack data is available, first check if you already posted in the product updates channel during the date range. If so, surface those posts and identify shipped work that hasn't been announced yet.

**For each shippable deliverable, generate a post using this template:**

```markdown
:sparkles: *What's New?*
{What was built — plain language, no ticket numbers. 2-3 sentences describing the feature from the user's perspective. What can they do now that they couldn't before?}

:dart: *Why It Matters*
{Business impact. How does this help users, internal teams, or the platform? If Sentry data available, include impact numbers. Connect to broader goals.}

:busts_in_silhouette: *Who's Impacted?*
{Teams and roles affected. What changes in their workflow. Use @mentions for team handles if known.}

:raised_hands: *Shout-Outs*
{People who contributed. Pull from PR authors, Asana task assignees, reviewers who gave substantive feedback.}
```

**Optional sections** (include when relevant):
- `:gear: *How It Works*` — brief technical explanation for complex features
- `:video_camera: *Demo*` — if a Loom link was found in Slack or PR descriptions
- `:soon: *What's Next*` — if there are related open PRs or upcoming Asana tasks

**ANNOUNCE mode rules:**
- Filter to merged PRs that are features (not hotfixes, reverts, or operational fixes)
- Group into 1-3 separate announcements if multiple features shipped
- Generate as drafts — show to user in terminal for review before posting
- If `--slack product-updates` is included, post after user confirms
- If only 1 feature, generate 1 post. If 2-3, generate separate posts.
- Never auto-post without the user seeing the draft first

#### ANNOUNCE SHORT

Same template but condensed — shorter descriptions, skip "How It Works" and "What's Next". One combined post for all features instead of separate ones.

## Step 5: Slack Posting (Optional)

Only if the user included `--slack #channel` or `--slack @user` or explicitly asks to post to Slack:

1. Use ToolSearch to find Slack MCP tools (search for "slack send")
2. Use `mcp__claude_ai_Slack__slack_send_message` to post the report
3. **Format for Slack** (Slack markdown, not GitHub markdown):
   - Use `*bold*` not `**bold**`
   - Use bullet points with `•`
   - Use plain URLs (Slack auto-unfurls GitHub and Asana links)
   - For `--announce` mode, use the emoji-header format exactly as shown in the template
4. For `--announce` with `--slack product-updates`, show the draft first and ask for confirmation before posting
5. If Slack MCP is not available, tell the user and show the report in terminal only

## Report Guidelines (All Modes)

- **Always include links** — PRs, Asana tasks, Sentry issues, commits. This is non-negotiable.
  - PRs: `[#32517](url)` from `gh` output
  - Asana: `[Task name](permalink_url)` from MCP
  - Commits: `[hash](repo_url/commit/full_hash)` from `gh repo view` + git log
  - Sentry: `[Issue title](url)` from Sentry MCP
  - Slack: plain URLs for Slack output, markdown links for terminal
- **Omit empty sections** — never show a section header with zero items
- **Single day reports** use "Work Report: {DATE}" instead of a range
- **Impact framing** (NARRATIVE and ANNOUNCE modes): always describe *what changed for users/the team*, not what files were modified
- **On-call collapsing**: never list 8 identical "Delete duplicated profile" tasks individually — collapse with count and one example link

## Error Handling

- Each data source is independent — if one fails, continue with the others
- If ALL sources return empty data, say "No activity found for {date range}. Check that you're in the right git repo and `gh` is authenticated."
- Never show raw error output from failed commands — fail silently per source
- If `gh` auth fails, suggest running `gh auth login`
- For `--announce` mode, if no shippable features are found, say "No features to announce for this period. Try `--log` or default mode to see all activity."
