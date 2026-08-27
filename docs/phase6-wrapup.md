# Phase 6 — Wrap-up

## What was built

A two-host Splunk SIEM lab for SOC role preparation.

| Host | Role |
|---|---|
| Laptop `192.168.1.192` | Splunk Enterprise — indexer, search head, Splunk Web |
| Main PC `192.168.1.90` | Sysmon (Olaf Hartong's sysmon-modular) + Universal Forwarder |

Four Windows Event Log channels forward to a dedicated `endpoint` index over TCP 9997:
Sysmon Operational (XML-rendered), Security, System, PowerShell Operational. Field
extraction comes from the Splunk Add-on for Microsoft Windows and the Splunk Add-on for
Sysmon. Six detections mapped to MITRE ATT&CK run as scheduled alerts on a 15-minute cron
against a 60-minute window, throttled per host.

## What actually took the time

The install was the easy part. Four failures each presented as "everything looks healthy"
and each had to be traced down a layer:

**1. Network — no inbound rule for 9997.** The forwarder installed cleanly and the service
reported `Running`, but the indexer was unreachable. Splunk's installer does not create a
firewall rule for the receiving port. Diagnosed by scanning the subnet and finding nothing
listening on any Splunk port, which ruled out a stale IP.

**2. Service account — Sysmon channel silently dropped.** Security, System and PowerShell
events flowed; Sysmon did not. The forwarder runs as the virtual account
`NT SERVICE\SplunkForwarder`, which is not a member of **Event Log Readers** by default.
The Sysmon channel's ACL is tighter than Security's, so it alone was rejected with
`errorCode=5` in `splunkd.log` while everything else looked fine.

**3. Parsing — add-on installed but never matched.** With both add-ons installed, every CIM
field (`process_name`, `parent_process_name`, `CommandLine`, `user`) came back empty. The
Splunk Add-on for Sysmon keys on XML-rendered events; the forwarder was shipping classic
format. Fixed with `renderXml = true` on the Sysmon stanza.

**4. Collection — a detection that could not fire.** The LSASS credential-dumping
detection returned nothing. Not a broken search: sysmon-modular restricts ProcessAccess
collection against `lsass.exe` to credential-dumping-grade access masks inside the Sysmon
config itself. The filtering happens two layers below the search, before the event is ever
written. The detection was rewritten to match what the config actually collects.

The common thread: **service health told us nothing about data health.** Every one of these
presented with green services and a working dashboard.

## Validation

Detection 02 (encoded PowerShell) was proven end to end by running a benign
`powershell.exe -enc` command and confirming it surfaced with the full command line and
correct user attribution. That single test exercises Sysmon capture, forwarding, XML
rendering, add-on parsing, and detection logic together.

Detection 04 (scheduled task creation) later fired on a real software install, which
provided the first live triage: check the parent process and what the task runs, decide
benign, and resist tuning off a single event.

## Honest gaps

- Detections 01, 05 and 06 have never fired. Their logic is unvalidated.
- Detection 05's `Service_*` field names remain unconfirmed — no 7045 has occurred.
- The Sysmon baseline is hours, not weeks. Anything that only runs nightly or weekly is
  not represented.
- Phase 5 (Tailscale) was not completed. LAN access made it optional; Tailscale on the
  main PC is still unconfigured.
- Single 60-day Splunk trial with no renewal plan.

## Status: ✅ complete
