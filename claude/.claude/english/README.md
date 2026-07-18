# English learning system 🇬🇧💵

Two global Claude Code slash commands to learn English while I work, aiming for
professional fluency to earn in USD.

## Commands

| Command | What it does |
|---------|--------------|
| `/en <message in English>` | Corrects my English, suggests more natural phrasing, logs my errors/strengths to `log.jsonl`, then does the actual task. Use it **every time** I want to practice. |
| `/en-review [days]` | Reads the whole `log.jsonl`, finds my recurring mistakes, shows progress trends, and gives a targeted study plan. Run ~weekly. Saves a snapshot in `reviews/`. |

Command files live in `~/.claude/commands/en.md` and `~/.claude/commands/en-review.md`.

## Data

- `log.jsonl` — one JSON line per `/en` message (the source of truth for reviews).
- `reviews/YYYY-MM-DD.md` — saved weekly review snapshots.

### `log.jsonl` schema
```json
{
  "ts": "2026-07-17T23:10:00Z",
  "original": "what I wrote",
  "corrected": "fixed version or null",
  "natural": "more natural phrasing or null",
  "errors": [{ "type": "preposition", "wrong": "in Monday", "right": "on Monday", "note": "days take 'on'" }],
  "did_well": ["used present perfect correctly"],
  "score": 8,
  "level_estimate": "B1"
}
```

## Versioning with stow

This lives under `~/.claude/`, so package it in your dotfiles as a `claude` stow package:

```
~/Dotfiles/claude/.claude/commands/en.md
~/Dotfiles/claude/.claude/commands/en-review.md
~/Dotfiles/claude/.claude/english/README.md
```

Then `cd ~/Dotfiles && stow claude` symlinks them into `~/.claude/`.

**Tip:** the commands + this README are config worth committing. `log.jsonl` and
`reviews/` are personal *data* that grow over time — commit them too if you want a
backup of your progress, or add them to `.gitignore` if you'd rather keep only the tooling.
