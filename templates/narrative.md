# Narrative Mode Templates

## NARRATIVE DETAILED

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

## NARRATIVE SHORT

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
