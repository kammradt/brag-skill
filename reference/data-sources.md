# Data Source Collection Reference

Run ALL sources in parallel. Each source is independent — if one fails, continue with the others.

## Config-Aware Collection

If a `config.json` was loaded, use it to optimize:
- **Skip disabled sources**: If `sources.{name}.enabled` is `false`, skip entirely
- **Use stored values**: `sources.git.author_name` for git log, `sources.slack.user_id` for Slack searches, etc.
- **Skip ToolSearch for known MCP sources**: If config says a source is enabled, use MCP tools directly

If no config exists, fall back to auto-detect (search for tools, infer values).

## Source 1: GitHub PRs and Repo URL (Bash)

Run three commands in parallel:

**PRs authored:**
```bash
gh pr list --search "author:@me created:>=${START} created:<=${END}" --state=all --limit 100 --json number,title,state,url,createdAt,mergedAt,additions,deletions,reviewDecision
```

**PRs reviewed:**
```bash
gh pr list --search "reviewed-by:@me -author:@me created:>=${START}" --state=all --limit 100 --json number,title,state,url
```

**Repo base URL** (for commit links):
```bash
gh repo view --json url -q .url
```

If `gh` is not authenticated or fails, skip silently.

## Source 2: PR Review Depth (Bash, for NARRATIVE and LOG modes)

For each PR you reviewed, fetch review details to classify quality:

```bash
GH_USER=$(gh api user --jq .login)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq "[.[] | select(.user.login == \"${GH_USER}\")] | length"
```

Classify each reviewed PR as:
- **Approved (no comments)** — quick approval
- **Approved with feedback** — substantive review with comments
- **Changes requested** — caught issues that needed fixing

## Source 3: Git Commits (Bash)

```bash
git log --author="${GIT_AUTHOR}" --since="${START}" --until="${END} 23:59:59" --format="%h|%H|%ad|%s" --date=short --no-merges --all
```

Format includes short hash (`%h`) for display and full hash (`%H`) for commit URL links.

## Source 4: Claude Code Sessions (Glob + Read)

1. **Read `~/.claude/history.jsonl`** — each line is JSON with `sessionId`, `timestamp` (Unix ms), `project`, `display` (first user message). Filter by date range.
2. **Deduplicate by sessionId**, keeping first and last timestamps per session. Extract:
   - **Project**: from directory path (last segment)
   - **Task summary**: first `display` value (truncate to ~80 chars)
   - **Message count**: entries per session
   - **Duration**: difference between first and last timestamps
3. Limit to 20 most recent sessions.

## Source 5: Asana Tasks (MCP, optional)

1. Use ToolSearch for "asana" (or skip if config says enabled)
2. Use `mcp__asana__asana_search_tasks`:
   - Tasks assigned to "me" completed in date range
   - `completed_on.after` = START_DATE, `completed_on.before` = day after END_DATE
   - `opt_fields`: `name,completed_at,memberships.project.name,permalink_url`
3. If unavailable, skip silently

## Source 6: Slack Activity (MCP, optional)

1. Use ToolSearch for "slack search" (or skip if config says enabled)
2. Get current user's Slack ID from config or tool descriptions
3. Search: `from:<@{SLACK_USER_ID}> after:{START_UNIX} before:{END_UNIX}`

**Filter by signal level:**

| Level | Include | Examples |
|-------|---------|----------|
| **High** (always) | Product updates channel posts, messages with 3+ reactions, Loom links, thread starters in eng channels | Announcements, demos |
| **Medium** (NARRATIVE only) | On-call/incident channels, PR links, deploy notifications | Operational comms |
| **Low** (skip) | Replies under 20 chars, social/random/off-topic channels | "ok", "thanks" |

**Per-mode usage:**
- `--log`: not used
- NARRATIVE: enriches "Kept the Lights On" and "Helped the Team"
- `--announce`: pulls product updates channel posts verbatim, identifies unannounced shipped work

## Source 7: Sentry Issues (MCP, optional)

1. Use ToolSearch for "sentry" (or skip if config says enabled)
2. Use `mcp__sentry__search_issues` for resolved issues in date range
3. Extract: issue title, URL, times seen, users affected, resolution speed
4. If unavailable, skip silently

This data enriches impact framing: "Fixed ingestion failure affecting 12 workflows" is stronger than "merged PR #32380".
