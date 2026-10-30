# Claude auto-resume setup (Claude Code 2.1.310, Windows, Pro subscription)

Written 2026-10-25. Evidence tags: CONFIRMED = read in the installed binary's own source text or observed locally; UNTESTED = follows from the source but was not exercised (I did not burn quota to test).

## In plain English

- **Normal 5-hour limit:** if you start Claude with `.\scripts\Start-RdxClaude.ps1`, Claude waits out the limit itself (it sleeps, rechecks about every 5 minutes whether the limit lifted early, then retries the same request and carries on). Nothing to do.
- **Weekly (or any reset more than 6 hours away):** Claude does **not** sleep for days. It stops with an error. Our checkpoint file `analysis\agent-reviews\CLAUDE-CURRENT-WORK.md` says where we were. Resume later with `.\scripts\Start-RdxClaude.ps1 -Resume`, or schedule it (below).
- **Disable:** just start Claude normally (`claude`) instead of the launcher. Nothing global was changed. To remove the optional one-shot task: `.\scripts\Start-RdxClaude.ps1 -CancelScheduledResume`.
- No API key, no extra-usage purchase, no `--dangerously-skip-permissions`.

## Commands

| Goal | Command |
|---|---|
| Start the lead session with the watchdog on | `.\scripts\Start-RdxClaude.ps1` |
| Continue the last project conversation (reads the checkpoint first) | `.\scripts\Start-RdxClaude.ps1 -Resume` |
| Resume once at a chosen time (e.g. after a weekly reset) | `.\scripts\Start-RdxClaude.ps1 -ScheduleResumeAt "2026-10-30 09:00"` |
| Remove that scheduled resume | `.\scripts\Start-RdxClaude.ps1 -CancelScheduledResume` |
| Show what would run, start nothing | add `-DryRun` |

Logs and the one-launcher-at-a-time lock live in `%LOCALAPPDATA%\RdxClaude\` (outside the repo, never committed).

## What 2.1.310 actually supports

| Feature | Finding |
|---|---|
| `autoContinueAtUsageLimit` setting | CONFIRMED exists ("Continue automatically at usage limit", `/config`). Description: waits for the claude.ai limit to reset and continues. **Effective default is ON** when the key is absent (`hHn`: setting ?? key-absent). Your `~/.claude/settings.json` has only `theme` and `model`, so it is on by default. It is consent-gated (cannot be flipped by the model; toggle in `/config` yourself). Gated by: subscription (non-usage-billed) account, server feature flags, reset must be within an internal window, at most 2 auto-continues per episode. **UNKNOWN** whether those gates pass for a background/unattended session: they depend on server flags and helper functions I could not resolve from the minified code. Treat as a bonus, not the guarantee. I did not change it. |
| `CLAUDE_CODE_RETRY_WATCHDOG` | CONFIRMED in the retry layer: on a 429 with `anthropic-ratelimit-unified-status: rejected` it sleeps until the reset time (each sleep chunk capped at 6 h) instead of failing. The code path is the API retry layer, not the interactive dialog, so it is independent of attended/background mode. Read from the process environment at startup: **it cannot be turned on inside an already-running session.** |
| `..._MAX_USAGE_LIMIT_WAIT_MS` | CONFIRMED: if time-to-reset exceeds the remaining allowance, the request fails with `api_request_usage_limit_wait_too_long` rather than waiting. With 21600000 (6 h): a 5-hour window is waited out; a weekly reset is not. |
| `..._USAGE_LIMIT_RECHECK_MS` | CONFIRMED: interval for probing whether the limit lifted early (backoff, bounded). Set to 300000 as requested. |
| `..._MAX_WAIT_MS` | CONFIRMED: total cap on one waiting episode. Set to 28800000 (8 h) as a safety stop. |
| `CLAUDE_CODE_RETRY_WATCHDOG_SCOPE` | CONFIRMED exists (not in your list). Value `capacity` limits the watchdog to overload errors only, so we leave it unset to cover usage limits. |
| `CLAUDE_CODE_SESSION_ATTENDED` | CONFIRMED only records whether an attended session spawned this one; it does not gate auto-continue. This session shows `0` (background job). |
| `claude --continue`, `--resume <id>`, `--bg`, `claude respawn` | CONFIRMED in `claude --help`. |
| `CLAUDE_MOCK_HEADERLESS_429` | I tried it as a safe simulator: **it did nothing** (reply came back "ok" in 4.5 s). So an end-to-end limit test is not possible without really hitting the limit. |

## Honest status

- **This current background session was started without the watchdog**, so it is covered only by the native setting (UNKNOWN for this session type). Sessions started through `Start-RdxClaude.ps1` get the watchdog (CONFIRMED by source, UNTESTED against a real limit).
- Layer 3 (Task Scheduler) is provided only as a **one-shot** resume you schedule on purpose. There is no self-respawning loop. Tested: task creation, listing and deletion work on this machine. The scheduled run opens `Start-RdxClaude.ps1 -Resume`, which reads the checkpoint, checks real Git/process state and refuses to start if another launcher holds the lock. It runs only while you are logged on.
- A resumed session still obeys all project boundaries (no live work, no commit, no push).

## Third-party tool already installed: `unsnooze` 1.20.1

`C:/Users/REDACTED\AppData\Roaming\npm\unsnooze` (MIT, npm; `.unsnooze\update-check.json` in this repo shows it ran here before). It claims to resume Claude Code and Codex sessions after limits via a Stop hook + `claude --resume`, and says it never uses `--dangerously-skip-permissions`. Your `settings.json` has no hooks, so it is **not currently active**. I did not enable or run it: it installs hooks into your global settings and runs a background daemon, and the first-party watchdog covers the main case. It could be a later option for **Codex** limits, which the first-party watchdog cannot cover.
