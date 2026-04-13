# Date Parsing Reference

## Time Range Arguments

| Argument | START_DATE | END_DATE |
|---|---|---|
| Empty / `today` | today | today |
| `yesterday` | yesterday | yesterday |
| `week` / `this_week` | Monday of current week | today |
| `last_week` | Monday of prev week | Sunday of prev week |
| `Nd` (e.g. `7d`, `14d`) | N days ago | today |
| `YYYY-MM-DD..YYYY-MM-DD` | first date | second date |

Also accept natural language like "last two weeks" = 14d, "this month" = 1st of month to today.

## Bash Date Arithmetic (macOS `date -v`)

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
