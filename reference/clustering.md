# Auto-Clustering Reference

Before generating the report, **cluster related items into deliverables**. This is critical for NARRATIVE and ANNOUNCE modes. Skip this step for LOG mode.

## Clustering Rules

1. **By ticket prefix**: items sharing an Asana ticket or JIRA-style prefix (e.g. `EGL-3604`, `EGL-3601`) are likely the same initiative
2. **By branch name**: commits and PRs on the same branch belong together
3. **By keyword overlap**: PR titles, commit subjects, and Asana task names with significant word overlap (ignoring common words like "fix", "update", "add")
4. **Collapse repetitive items**: multiple identical Asana tasks (e.g. 8x "Delete duplicated profile") become one line with a count

## Cluster Output

Each cluster becomes a deliverable with:
- A short descriptive title (not a PR title — a human summary)
- The list of associated PRs, commits, Asana tasks, and Sentry issues (with links)
- An impact statement: what changed and why it matters

## Theme Categorization

Categorize each deliverable into one of four themes:

| Theme | What belongs here |
|-------|-------------------|
| **Shipped** | Merged PRs linked to feature Asana tasks (not from "On-call" projects). New capabilities that went to production. |
| **Kept the Lights On** | Items from Asana "On-call" projects, hotfixes, reverts, Sentry issues, incident-channel Slack messages. Operational work. |
| **Invested in the Future** | Tooling, documentation, skills, refactors, DX improvements, test improvements. Work that pays off later. |
| **Helped the Team** | PRs reviewed (with depth classification), cross-pod Asana tasks, Slack threads where you unblocked others. Multiplier work. |

## Categorization Heuristics

- Asana project name contains "On-call" → Kept the Lights On
- PR title starts with "Revert" or "hotfix" → Kept the Lights On
- PR title contains "refactor", "docs", "skill", "tooling", "DX" → Invested in the Future
- Sentry-linked PRs → Kept the Lights On
- PRs you reviewed (not authored) → Helped the Team
- Everything else → Shipped
