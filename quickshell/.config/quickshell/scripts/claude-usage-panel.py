#!/usr/bin/python3
"""Terminal fallback for the bar's usage panel. Reads claude-usage-collect.py.

r reloads, q quits.
"""

import datetime as dt
import json
import subprocess
import sys
import termios
import tty
from pathlib import Path

COLLECTOR = Path(__file__).with_name("claude-usage-collect.py")

BAR_WIDTH = 24
BAR_FULL = "█"
BAR_EMPTY = "░"

BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"
CLEAR = "\033[2J\033[H"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"

WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

LABELS = {"Session (5-hour)": "Session (5h)", "Weekly (7-day)": "Weekly (7d)"}


def collect(force=False):
    args = [sys.executable, str(COLLECTOR)]
    if force:
        args.append("--force")
    out = subprocess.run(args, capture_output=True, text=True, timeout=60)
    if out.returncode != 0 or not out.stdout.strip():
        raise RuntimeError(out.stderr.strip() or "collector produced no output")
    return json.loads(out.stdout)


def humanize(n):
    for cutoff, suffix in ((1_000_000_000, "B"), (1_000_000, "M"), (1_000, "k")):
        if n >= cutoff:
            return f"{n / cutoff:.1f}{suffix}"
    return str(int(n))


def bar(value, peak, width=BAR_WIDTH):
    filled = 0 if peak <= 0 else min(width, round(value / peak * width))
    return BAR_FULL * filled + BAR_EMPTY * (width - filled)


def countdown(iso):
    if not iso:
        return "-"
    left = dt.datetime.fromisoformat(iso) - dt.datetime.now(dt.timezone.utc)
    secs = int(left.total_seconds())
    if secs <= 0:
        return "now"
    days, secs = divmod(secs, 86400)
    hours, secs = divmod(secs, 3600)
    minutes = secs // 60
    if days:
        return f"{days}d {hours}h"
    if hours:
        return f"{hours}h {minutes:02d}m"
    return f"{minutes}m"


def short_model(name):
    name = name[len("claude-"):] if name.startswith("claude-") else name
    head, _, tail = name.rpartition("-")
    if head and len(tail) == 8 and tail.isdigit():
        name = head
    return name if len(name) <= 13 else name[:12] + "…"


def section(title):
    return f"\n  {DIM}{title}{RESET}\n"


def render(data):
    out = [CLEAR]

    tier = data.get("tierLabel")
    head = "Claude Code" + (f"  ·  {tier}" if tier else "")
    out.append(f"\n  {BOLD}{head}{RESET}\n")

    status = data.get("usageStatusText") or ""
    if status:
        out.append(f"  {DIM}{status}{RESET}\n")

    limits = data.get("limits") or []
    if limits:
        out.append(section("LIMITS"))
        for limit in limits:
            label = LABELS.get(limit.get("label", ""), limit.get("label", "?"))
            pct = round(float(limit.get("percent") or 0) * 100)
            reset = countdown(limit.get("resetsAt"))
            out.append(
                f"  {label:<14}{bar(pct, 100)} {pct:>3}%   {DIM}resets in {reset}{RESET}\n"
            )

    days = data.get("recentDays") or []
    if days:
        out.append(section("TOKENS BY DAY"))
        peak = max((d.get("messageCount") or 0) for d in days) or 1
        today = dt.date.today().isoformat()
        for day in days:
            date = day.get("date", "")
            tokens = day.get("messageCount") or 0
            try:
                label = f"{WEEKDAYS[dt.date.fromisoformat(date).weekday()]} {date[8:]}"
            except ValueError:
                label = date
            is_today = date == today
            prefix = BOLD if is_today else ""
            suffix = ""
            if is_today:
                bits = []
                if data.get("todayPrompts"):
                    bits.append(f"{data['todayPrompts']} prompts")
                if data.get("todaySessions"):
                    bits.append(f"{data['todaySessions']} sessions")
                if bits:
                    suffix = f"   {DIM}{' · '.join(bits)}{RESET}"
            out.append(
                f"  {prefix}{label:<14}{bar(tokens, peak)} {humanize(tokens):>7}{RESET}{suffix}\n"
            )

    models = data.get("modelUsage") or {}
    if models:
        out.append(section("TOKENS BY MODEL"))
        totals = {name: sum(v.values()) for name, v in models.items()}
        peak = max(totals.values()) or 1
        for name in sorted(totals, key=totals.get, reverse=True):
            usage = models[name]
            out.append(
                f"  {short_model(name):<14}{bar(totals[name], peak)} {humanize(totals[name]):>7}\n"
            )
            cache = usage.get("cacheReadInputTokens", 0) + usage.get("cacheCreationInputTokens", 0)
            out.append(
                f"  {DIM}{'':<14}in {humanize(usage.get('inputTokens', 0))} · "
                f"out {humanize(usage.get('outputTokens', 0))} · "
                f"cache {humanize(cache)}{RESET}\n"
            )

    foot = []
    if data.get("totalPrompts"):
        foot.append(f"{data['totalPrompts']} prompts")
    if data.get("totalSessions"):
        foot.append(f"{data['totalSessions']} sessions")
    if data.get("activeDays"):
        foot.append(f"{data['activeDays']} active days")
    if foot:
        out.append(f"\n  {DIM}{' · '.join(foot)}{RESET}\n")

    out.append(f"\n  {DIM}r reload · q quit{RESET}\n")
    return "".join(out)


def read_key():
    fd = sys.stdin.fileno()
    saved = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, saved)


def main():
    force = False
    sys.stdout.write(HIDE_CURSOR)
    try:
        while True:
            try:
                sys.stdout.write(render(collect(force)))
            except Exception as err:  # noqa: BLE001
                sys.stdout.write(f"{CLEAR}\n  Usage unavailable: {err}\n\n  {DIM}r reload · q quit{RESET}\n")
            sys.stdout.flush()
            force = False

            key = read_key()
            if key in ("q", "Q", "\x1b", "\x03"):
                return
            if key in ("r", "R", "\r", "\n"):
                force = True
    finally:
        sys.stdout.write(SHOW_CURSOR + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
