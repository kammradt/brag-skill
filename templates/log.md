# Log Mode Templates

## LOG DETAILED

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

## LOG SHORT

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
