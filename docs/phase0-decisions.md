# Phase 0 — Decisions

Record of the scoping conversation before any work started.

## Goal
Get hands-on familiarity with a SIEM (Splunk), specifically for SOC role applications.
Detection/alerting content is the primary focus, not just log collection.

## Scope decisions

| Question | Decision | Why |
|---|---|---|
| Data source | Host-based visibility only (Sysmon + Windows Event Logs) via main PC | Netflow/packet capture needs router support that may not exist; host-based is what most SOC detection content is built around anyway |
| Splunk topology | This machine = indexer + search head + Splunk Web; main PC = forwarder only | Simplest single-instance lab setup |
| UI | Native Splunk Web — no custom UI built | Splunk Web persists even after the trial license lapses (only scheduled search/alerting is lost), so a custom UI wasn't needed |
| Licensing | Single 60-day Enterprise trial, no renewal cadence | This is a learning project, not a production deployment — treat day 60 as a natural checkpoint |
| Detection/alerting | Core focus, built with scheduled searches + alert actions | Directly relevant to SOC analyst work (triage, tuning, correlation searches) |
| Sysmon config | Olaf Hartong's Sysmon-Modular (over SwiftOnSecurity) | More volume/noise = closer to real SOC conditions and tuning experience; maps to MITRE ATT&CK; more commonly referenced in real detection-engineering work |
| Tailscale exposure | Splunk Web published to tailnet only (no Funnel/public internet) | This is personal network telemetry — keep it private to your own devices |
| Auth on the Tailscale-exposed UI | None beyond tailnet membership | Acceptable for a home lab; Tailscale ACLs are the gate |

## Known constraint carried into every later phase
Work is driven from the laptop, not the main PC, and the working shell is
not running as Administrator. See `phase1-install-splunk.md` for how that's handled.

## Status: ✅ Done
