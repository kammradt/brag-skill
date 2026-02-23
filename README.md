# /brag — Developer Accomplishment Reports for Claude Code

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that generates developer accomplishment reports by aggregating data from multiple sources:

- **GitHub** — PRs authored, PRs reviewed (with review depth)
- **Git** — commits across all branches
- **Asana** — completed tasks (via MCP)
- **Slack** — high-signal messages and announcements (via MCP)
- **Sentry** — resolved issues with impact numbers (via MCP)
- **Claude Code** — session history

## Install

### One-liner

```bash
curl -sSL https://raw.githubusercontent.com/kammradt/brag-skill/main/install.sh | bash
```

### Ask Claude Code

Open Claude Code and say:

> Install the /brag skill from https://github.com/kammradt/brag-skill

### Manual

```bash
mkdir -p ~/.claude/skills/brag
curl -sSL https://raw.githubusercontent.com/kammradt/brag-skill/main/SKILL.md -o ~/.claude/skills/brag/SKILL.md
```

### Developer Setup

If you're working on the skill itself, use `--dev` to symlink the repo directly:

```bash
# From inside your clone of this repo:
./install.sh --dev

# Or via curl (clones to ~/repos/brag-skill, then symlinks):
curl -sSL https://raw.githubusercontent.com/kammradt/brag-skill/main/install.sh | bash -s -- --dev
```

This creates a symlink `~/.claude/skills/brag` -> your repo directory. Edits to `SKILL.md` are immediately reflected in Claude Code — no reinstall needed. Use `git pull`/`push` to stay in sync.

## Setup

Run `/brag setup` to configure data sources and default preferences:

```
/brag setup
```

Setup auto-detects available tools (GitHub CLI, Git, Asana MCP, Slack MCP, Sentry MCP, Claude Code sessions) and asks a few questions to personalize your config. It saves a `config.json` alongside `SKILL.md`.

With a config, `/brag` without arguments uses your defaults (e.g. narrative mode, last week) instead of showing help.

Setup is optional — the skill works without it using auto-detection, but config makes it faster and more personalized.

## Usage

```
/brag <time range> [--log | --announce] [--short] [--slack #channel]
/brag setup
```

### Time ranges

| Argument | Range |
|---|---|
| `today` | Today's activity |
| `yesterday` | Yesterday's activity |
| `week` | Monday to today |
| `last_week` | Last Monday through last Sunday |
| `7d`, `14d` | Last N days |
| `2026-02-01..02-14` | Custom date range |
| `"last two weeks"` | Natural language |

### Output modes

| Flag | Mode |
|---|---|
| _(default)_ | **Narrative** — grouped by impact themes (Shipped, Kept the Lights On, Invested in the Future, Helped the Team) |
| `--log` | **Technical changelog** — organized by data source |
| `--announce` | **Product announcement** — stakeholder-facing format |

### Options

| Flag | Effect |
|---|---|
| `--short` | Condensed ~15-25 line version |
| `--slack #channel` | Post the report to a Slack channel |
| `--slack @user` | Send as a Slack DM |

## Examples

```bash
/brag setup                            # Configure sources and preferences
/brag last_week                        # Narrative report for last week
/brag 14d --short                      # Quick 2-week summary
/brag last_week --log                  # Technical changelog
/brag last_week --announce             # Product update draft
/brag week --short --slack #standup    # Short report posted to Slack
```

## How it works

1. **Collects data** from all sources in parallel
2. **Clusters** related items into deliverables (by ticket prefix, branch, keyword overlap)
3. **Categorizes** each deliverable into impact themes
4. **Generates** a report with links, impact framing, and collapsed repetitive items

MCP-dependent sources (Asana, Slack, Sentry) are optional — the skill works with just GitHub and git, and gets richer as you add MCP integrations.

## Author

**Vinicius Kammradt** — [GitHub](https://github.com/kammradt) · [LinkedIn](https://www.linkedin.com/in/vinicius-kammradt/)

## License

MIT
