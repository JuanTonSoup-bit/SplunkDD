# Phase 2 — Instrument the main PC

Everything in this phase runs **on the main PC**, not the laptop.
This is a script + doc package — run it there, then record the results (or re-verify
remotely once Phase 5's Tailscale link exists).

## Prerequisite: indexer side ready

Phase 3's steps 1–2 (create `endpoint` index, enable receiving port 9997) must be done
first, or the forwarder will connect but have nowhere to send data / no port to hit.

## What the script does (`main-pc-scripts/setup-main-pc.ps1`)

1. Downloads Sysmon from Microsoft Sysinternals.
2. Downloads **Olaf Hartong's Sysmon-Modular** config directly from his GitHub repo
   (`sysmonconfig.xml`).
3. Installs Sysmon with that config (`sysmon64.exe -accepteula -i sysmonconfig.xml`).
4. Downloads Splunk Universal Forwarder 10.4.2.
5. Installs it silently, pointed at this machine (`192.168.1.192:9997`), with the
   Security and System Windows Event Log channels enabled via install-time flags.
6. Drops in `inputs.conf` (copied alongside the script) to also forward:
   - `Microsoft-Windows-Sysmon/Operational` (the actual Sysmon telemetry)
   - `Microsoft-Windows-PowerShell/Operational`
   — these two aren't covered by the UF installer's built-in flags, so they're added
   as a manual config file.
7. Restarts the forwarder service to pick up the config.

## What you need to do

1. Copy the whole `main-pc-scripts\` folder to the main PC (USB, network share,
   OneDrive, whatever's convenient).
2. Open `setup-main-pc.ps1` and edit the top two variables:
   - `$ForwarderPassword` — set a real password (this is local to the forwarder, not
     shared with the indexer's admin account).
   - `$IndexerAddr` — only change if `192.168.1.192` isn't this machine's current LAN
     IP by the time you run it.
3. Run it from an **elevated** PowerShell on the main PC:
   ```powershell
   cd C:\path\to\main-pc-scripts
   .\setup-main-pc.ps1
   ```
4. Verify locally on the main PC:
   ```powershell
   Get-Service Sysmon64, SplunkForwarder
   ```
   both should show `Running`.

## Verifying data arrives (done from the Splunk side, I can check this)

Once the script's run, tell me and I'll search `index=endpoint` in Splunk Web (or ask
you to) to confirm events are landing before moving to Phase 3's field-extraction step.

## A note on trust

This script downloads and executes a third-party Sysmon config file
(`sysmonconfig.xml` from `olafhartong/sysmon-modular` on GitHub) and runs it with
`-accepteula`. It's a widely-used, actively-maintained public repo, but it's still
worth a skim before running if you want to eyeball what it's configuring — it's just
Sysmon event-filtering rules, not executable code, so the risk is low, but worth being
aware of what "run this script" is fetching and applying.

## Status: ⬜ not started — waiting on Phase 3 steps 1–2, then handoff to you
