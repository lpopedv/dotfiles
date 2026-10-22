# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for Arch Linux + Hyprland, managed with GNU Stow - and the source of
**Lethe**, the distro built from them (the installer ISO, releases, the `lethe` command). The
repo and its path (`~/Dotfiles`) keep the dotfiles name; everything a user sees says Lethe.
The same repo runs on more
than one machine (an AMD desktop and a laptop), so system config must be hardware-agnostic:
no CPU-vendor, GPU or driver assumptions - when something only fits some hardware,
`bootstrap.sh` decides per machine (e.g. kernel lockdown is skipped where out-of-tree modules
exist). There is
no build/test/lint pipeline — "correctness" means the shell scripts are safe to re-run and the
stowed configs are valid for the tool that reads them.

## Repo layout

Each top-level directory is a **stow package**: its contents are rooted at `$HOME`, e.g.
`hypr/.config/hypr/keybinds.lua` stows to `~/.config/hypr/keybinds.lua`. `system/` is the only
top-level directory that is *not* a stow package — it holds installer/build tooling, not files
meant to land in `$HOME`.

## Commands

- Full machine bring-up (idempotent, safe to re-run): `system/install/bootstrap.sh`
  - `system/install/bootstrap.sh --dry-run` — print what would change, touch nothing
  - Order: pacman packages (`packages.txt`) → paru/AUR packages (`aur.txt`) → `stow --restow`
    every package → `mise install --locked` → pacman.conf tweaks → DNS/time hardening →
    maintenance timers → trace retention → firewall/sysctl hardening → Secure Boot →
    service enablement.
    Every step checks its own state before acting, so it's fine to run repeatedly.
  - `lethe update` (`bin/.local/bin/lethe`; `dotup` in `zsh/.zshrc` is an alias) is the
    normal way changes reach a machine: on the `stable` channel it checks out the newest
    *signed* release tag, on `edge` it pulls `main`, then runs this script.
    `lethe apply` re-runs it alone.
- Cut a release (owner, from a clean `main` matching origin): `lethe release vX.Y.Z` —
  SSH-signed tag, pushed; `.github/workflows/release.yml` builds and publishes the ISO.
- Stow/unstow one package by hand from the repo root: `stow --restow <pkg>` / `stow -D <pkg>`
  (the root `.stowrc` adds `--no-folding`, so this must run from the repo root)
- Build a live installer ISO that embeds this repo: `sudo system/iso/build.sh [workdir]`
  (defaults to `/var/tmp/archiso-work`, not `/tmp`, because it needs 10+ GB and `/tmp` is
  tmpfs). Requires a checked-out branch or tag (not a bare detached HEAD) and the `archiso`
  package.

There are no app-level build/test/lint commands — verify changes by checking `stow -n --restow
<pkg>` doesn't conflict, or by re-reading the target application's own config-loading rules.

## Architecture notes

**`system/install/`** is the source of truth for what a freshly-installed machine looks like:
`archinstall.json` is the initial installer profile, `packages.txt`/`aur.txt` are flat package
lists (one per line, `#` comments allowed) consumed by `bootstrap.sh`, and `etc/` holds drop-in
files bootstrap installs verbatim into `/etc` (systemd-resolved Cloudflare DNS-over-TLS, chrony with
NTS-authenticated time, nftables, sysctl hardening, NetworkManager/iwd per-boot MAC identity, volatile journald,
Docker publishing on 127.0.0.1 by default, no coredumps, and tmpfs mount units for `/var/log`, `/var/lib/lastlog`, `/var/lib/NetworkManager`).

**Amnesia rule:** the disk is an unencrypted SSD, where a deleted file's blocks linger until
trimmed - so traces are kept off the disk (tmpfs / `Storage=volatile`) rather than written and
wiped later. System-side that's the tmpfs units above plus `~/.cache`; user-side,
`systemd/.config/user-tmpfiles.d/traces.conf` turns state paths (nvim, lazygit, sddm session log, the whole Chromium profile,
Claude Code prompt history, herdr logs) into symlinks into `$XDG_RUNTIME_DIR`, and `zsh/.zshrc`
points shell/REPL histories there too. New trace sources should follow the same pattern. Comments in
`bootstrap.sh` explain *why* each of these exists (e.g. why `uwsm` is deliberately not
installed, why NetworkManager needs its own no-DNS drop-in in addition to systemd-networkd's).

**`system/iso/`** builds a custom archiso by copying the installed system's `releng` profile
(not vendored — archiso updates arrive for free) and layering `overlay/` on top, then
`git clone`s this repo's current branch or release tag (committed objects only — no stray
local/untracked changes ever ship) into the ISO's `airootfs/root/Dotfiles`, with an HTTPS origin.
`overlay/airootfs/root/install.sh` is the installer `.zlogin` starts on tty1: a `gum` wizard
(network, keyboard, account, disk, encryption) that builds an archinstall config from
`system/install/archinstall.json` plus the answers, validates it with archinstall `--dry-run`,
installs with `--silent`, then copies the repo into the new home and writes the per-machine
files (`~/.config/hypr/local.lua`, `~/.config/git/identity`). Its UI patterns and validation
rules come from Omarchy's installer (MIT). It must keep working with the archinstall version
releng ships — check archinstall's config schema when bumping anything disk-related.

**Releases and trust:** machines on the `stable` channel only install tags signed by a key in
`.github/allowed_signers`, read from the version they already run (CI checks a new tag against
the previous release's copy). So a new signing key ships in a release signed by an old one.
`lethe status --porcelain` feeds the bar's update indicator (`quickshell/.../UpdatesService.qml`).

**Owner vs. everyone:** this repo is installed by other people too. `lethe.owner` in the
repo's local `.git/config` (`lethe owner on`) adds the owner-only extras in `bootstrap.sh`:
`OWNER_STOW_PACKAGES` (`claude`) and `aur-owner.txt` (Mullvad). Personal data never goes in
tracked files: git identity is `~/.config/git/identity` (included by `git/.gitconfig`), and
per-machine Hyprland settings are `~/.config/hypr/local.lua` (loaded last by `hyprland.lua`).

**`hypr/`** — Hyprland config is written in **Lua**, loaded natively (Hyprland 0.56 / hyprlang
0.6.8 support Lua config directly — this is not a custom preprocessor). `hyprland.lua` is just a
sequence of `require()`s: `monitors → environment → autostart → look-and-feel → input →
keybinds → rules`. `hypridle.conf`, `hyprlock.conf`, and `hyprpaper.conf` are separate daemons
with their own native `.conf` syntax and are not part of this Lua chain.

**`quickshell/`** is a custom status bar/shell (not a config for someone else's bar) written in
QML against the Quickshell toolkit. `shell.qml` is the composition root, importing `bar/`,
`notifications/`, `osd/`, `session/` as sibling QML component folders. `scripts/` holds Python
helpers (`claude-usage-collect.py`, `claude-usage-panel.py`) that feed Claude API usage stats
into a bar widget.

**`nvim/`** uses Neovim's built-in `vim.pack` plugin manager (declared in `init.lua`), not
lazy.nvim/packer — `nvim-pack-lock.json` pins plugin revisions. Plugin config lives one-file-
per-plugin under `lua/plugins/`, each `require()`d from `init.lua` after the plugin list.

**`claude/`** (owner machines only) stows Claude Code's user config: `~/.claude/settings.json` (e.g. `cleanupPeriodDays`
for transcript retention, hooks), the `mono` theme, and an English-learning setup — the `en`,
`en-review` and `en-interview` skills, `hooks/en-auto.py` (a `UserPromptSubmit` hook that runs `en`
whenever a prompt is written in English) and `english/README.md`. The learning *data* the skills
write to `~/.claude/english/` (`log.jsonl`, `vocab.jsonl`, `reviews/`) is personal and never
versioned — this repo is public. The rest of `~/.claude` — transcripts, memory, credentials,
plugins — is local state and never versioned either. Claude Code rewrites `settings.json`
atomically when settings change from inside it, which replaces the stowed symlink with a regular
file; copy any wanted change back into the repo and restow.

**Every package is stowed with `--no-folding`** (`.stowrc` + explicit in `bootstrap.sh`): every
directory under `$HOME` is real and only files are symlinked. With folding, stow would turn a
directory into one symlink into this repo, and anything a program writes there (herdr's
sessions/sockets, Claude Code's transcripts, `systemctl --user enable`'s absolute per-user links)
would land in the repo. `bootstrap.sh` migrates installs that were folded: it moves the
`.gitignore`d runtime files out to `$HOME`, and warns if a program replaced a stowed symlink with
a regular file (an atomic save), since its changes would then no longer reach the repo.

## Gitignore-worthy state

Several things are deliberately excluded because they're generated/local, not source: the
`system/iso/out/` build output and `systemd/.config/systemd/user/*.wants/` (regenerated by
`systemctl --user enable` on every bootstrap run).
