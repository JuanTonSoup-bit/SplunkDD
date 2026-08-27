# Home SIEM Lab — Splunk Familiarity Project

**Goal:** Get hands-on familiarity with a SIEM (Splunk) for SOC role prep. Splunk runs
on this machine (indexer + search head + Splunk Web). The main PC forwards host-based
telemetry (Sysmon + Windows Event Logs) to it. Detection/alerting content is the primary
focus. Splunk Web is exposed over Tailscale (tailnet-only, no extra auth layer).

**Scope:** Deliberately host-based visibility only (no netflow/packet capture). Single
60-day Splunk Enterprise trial — no renewal plan, this is a learning project not a
production deployment.

## Folder layout

```
splunk/
├── docs/               <- one .md per phase, written as work happens
├── installers/         <- downloaded .msi/.exe installers (not committed anywhere, local only)
├── config/              <- exported Splunk configs, index definitions
│   └── spl/              <- saved searches / correlation search SPL, one file per detection
└── main-pc-scripts/     <- scripts + instructions to run ON THE MAIN PC (run there directly,
                            not from the laptop)
```

## Phase status

| Phase | Description | Status |
|---|---|---|
| 0 | Decisions | ✅ Done |
| 1 | Install Splunk (this machine) | ✅ Done — Splunkd running, ports 8000/8089 confirmed open |
| 3a | Indexer setup (index + receiving port + firewall) | ✅ Done |
| 2 | Instrument main PC (Sysmon + UF) | ✅ Done — all 4 sourcetypes confirmed flowing into `index=endpoint` |
| 3b | Field extraction / data quality | ✅ Done — Windows + Sysmon add-ons installed, CIM fields verified |
| 4 | Detection & alerting content | 🟡 Mostly done — 6 detections written, 5 scheduled; LSASS one pending tuning |
| 5 | Tailscale exposure | ⬜ Not started |
| 6 | Wrap-up | ⬜ Not started |

Note: Phase 3 got split — the index/receiving-port setup (3a) has to happen before
Phase 2's forwarder has anywhere to send data, so do 3a first, then Phase 2, then 3b.

## Key decisions (locked in)

- Host-based visibility only: Sysmon + Windows Event Logs, no raw packet/netflow capture.
- This machine = Splunk indexer + search head + Splunk Web (native UI, no custom UI built).
- Main PC = Universal Forwarder only.
- Sysmon config: **Olaf Hartong's Sysmon-Modular** (chosen over SwiftOnSecurity for
  realism — more volume/noise, closer to what a real SOC deals with, better interview
  talking points, maps to MITRE ATT&CK).
- Auth for Tailscale-exposed Splunk Web: tailnet membership only, no separate login layer.
- Single 60-day trial, no renewal cadence — at expiry, decide whether to reinstall or
  call the project done.

## Important constraint

Setup work is driven from **the laptop** (the indexer). Nothing reaches into the
main PC directly. Anything that needs to run there is written up as a doc + script in
`main-pc-scripts/` and executed on the main PC, with results recorded here.

Day-to-day work also runs **without Administrator rights**, so any step that installs a
Windows service (Splunk, Sysmon, Universal Forwarder) is prepared (downloaded, command
written out) but run separately in an elevated shell — both because of the permission
constraint and because service installs are hard to cleanly reverse.
