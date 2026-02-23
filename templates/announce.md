# Announce Mode Templates

## Product Announcement Template

For each shippable deliverable, generate a post using this template:

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

## Optional Sections (include when relevant)

- `:gear: *How It Works*` — brief technical explanation for complex features
- `:video_camera: *Demo*` — if a Loom link was found in Slack or PR descriptions
- `:soon: *What's Next*` — if there are related open PRs or upcoming Asana tasks

## ANNOUNCE Mode Rules

- Filter to merged PRs that are features (not hotfixes, reverts, or operational fixes)
- Group into 1-3 separate announcements if multiple features shipped
- Generate as drafts — show to user in terminal for review before posting
- If `--slack product-updates` is included, post after user confirms
- If only 1 feature, generate 1 post. If 2-3, generate separate posts.
- Never auto-post without the user seeing the draft first

## ANNOUNCE SHORT

Same template but condensed — shorter descriptions, skip "How It Works" and "What's Next". One combined post for all features instead of separate ones.
