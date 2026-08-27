# Phase 4 — Detection & alerting content

Detection SPL lives in `config/spl/`, one file per detection, each with a header giving
the ATT&CK technique, the data it depends on, what it catches, and its known noise
sources. The `.spl` files carry `#` comment headers that Splunk's search bar will not
accept — paste only the SPL body when creating a saved search.

## The detections

| # | Detection | MITRE | Data | Severity |
|---|---|---|---|---|
| 01 | Office or browser spawning a shell | T1059 | Sysmon EC 1 | Medium |
| 02 | Encoded / obfuscated PowerShell | T1059.001 | Sysmon EC 1 | Medium |
| 03 | LSASS memory access | T1003.001 | Sysmon EC 10 | High |
| 04 | Scheduled task created from CLI | T1053.005 | Sysmon EC 1 | Medium |
| 05 | New Windows service installed | T1543.003 | System 7045 | Medium |
| 06 | Windows event log cleared | T1070.001 | Security 1102 / System 104 | High |

## Alert settings

Each detection is saved as an alert with:

- **Schedule:** cron `*/15 * * * *`
- **Time range:** Last 60 minutes
- **Trigger:** Number of Results > 0
- **Action:** Add to Triggered Alerts

The 60-minute window against a 15-minute schedule overlaps deliberately, so an event that
indexes slowly can't fall between two runs. The cost is seeing the same event alert up to
four times, which is the right trade for a lab — a duplicate is noise, a miss is a failed
detection.

Time ranges are kept out of the `.spl` files on purpose so the same file works both as a
scheduled alert and as an ad-hoc hunting search over an arbitrary window.

## End-to-end validation (2026-08-26)

Detection 02 was validated against a command run deliberately on the main PC:

```powershell
powershell.exe -enc VwByAGkAdABlAC0ASABvAHMAdAAgAHQAZQBzAHQA
```

(harmless — decodes to `Write-Host test`). It surfaced in Splunk with `host=DESKTOP-1VS0CEB`,
`user=Juan`, `process_name=powershell.exe`, and the full `-enc` command line intact.

This is the single most useful check in the whole build: it proves Sysmon captured the
process creation, the forwarder shipped it, the add-on parsed it into CIM fields, and the
detection logic matched — the entire pipeline, confirmed by one observable event rather
than inferred from six services being green.

The other five parse and run clean but return zero results, which is expected for
detections of things that shouldn't be happening — and also means their logic is unproven.
Worth triggering each at least once the way 02 was.

## Known gaps

- **03 is not scheduled yet.** LSASS access fires legitimately from AV and Windows
  internals. The `GrantedAccess` masks in the file target memory-read patterns but were
  chosen without reference to this machine's baseline. Run it manually over 24 hours,
  exclude what turns out to be routine, then schedule it.
- **05's `Service_*` field names are unverified.** No 7045 event has occurred since
  collection started, so the columns have never been populated. Installing any piece of
  software will generate one and settle it.

## Status: ✅ alerts live 2026-08-26 — five of six scheduled and enabled

Created as saved alerts in Splunk Web (`Settings → Searches, reports, and alerts`):
Encoded Powershell, Event Log Cleared, New Service Installed, Office or Browser Spawning
Shell, Scheduled task Created. All enabled, all on `*/15 * * * *`.

Detection 03 (LSASS) is deliberately not scheduled — see Known gaps above.

### Gotcha worth remembering

The first save attempt failed with `rt time values are not allowed`. Cause: the alert's
Time Range was set to `1 hour window`, which is Splunk's **real-time** rolling window, not
the relative `Last 60 minutes`. Scheduled alerts reject real-time ranges. The two sit
next to each other in the time picker and read almost identically.

Same distinction matters for ad-hoc searching: the `... window` presets open a persistent
real-time search, which is noticeably heavier on an indexer that is also acting as search
head. Prefer `Last 60 minutes` / `Last 24 hours`.
