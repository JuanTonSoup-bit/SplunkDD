# Phase 1 — Install Splunk (this machine)

## Prerequisite check (done)

| Check | Result |
|---|---|
| OS | Windows 11 Home, build 10.0.26200 |
| RAM | 15.41 GB total — fine for a lab instance |
| Free disk | 861.87 GB free on `C:` — plenty |
| Admin rights (working shell) | **No** — see note below |
| Existing Splunk install | None found |
| Existing Tailscale install | None found |
| Existing Sysmon install | None found |

## Why the install step runs in a separate elevated shell

The working shell runs as a regular user, not Administrator. Installing Splunk
as a Windows service requires elevation (UAC), and a UAC prompt can't be answered by a
non-interactive shell — it would just hang. So the installer was downloaded and verified first,
and the actual install command is run in an elevated PowerShell/terminal. This is
also just good practice for anything that installs a system service.

## Installer downloaded

| | |
|---|---|
| Version | Splunk Enterprise 10.4.2 |
| Source | `https://download.splunk.com/products/splunk/releases/10.4.2/windows/splunk-10.4.2-33c3bf42cd73-windows-x64.msi` |
| Saved to | `C:\Users\jafal\Desktop\splunk\installers\splunk-10.4.2-windows-x64.msi` |
| Size | 1,074,774,016 bytes (~1.0 GB) |
| SHA256 | `68DE2EEB63B8392D2EF5AB4D6F2ECC55D531720261C389D53288ABDEE7435A41` |

(No published checksum was cross-checked against Splunk's site for this file — if you
want to be extra sure, compare against Splunk's download page before installing.)

## What you need to do — run the install

**Option A — GUI installer (recommended for a first install):**
1. Double-click the MSI at the path above.
2. Accept the license (this starts your 60-day Enterprise trial clock).
3. Choose "Local System" or a domain/local user account to run the Splunk service —
   Local System is fine for a lab.
4. Set the **admin username/password** when prompted — pick something you'll remember,
   this is what you log into Splunk Web with. Don't send it to me; just confirm here
   once it's set so I know to proceed.
5. Leave "Launch browser with Splunk" checked, or launch manually after.
6. Let it finish and start the `splunkd` service.

**Option B — silent CLI install (elevated PowerShell), if you'd rather script it:**
```powershell
msiexec.exe /i "C:\Users\jafal\Desktop\splunk\installers\splunk-10.4.2-windows-x64.msi" `
  AGREETOLICENSE=Yes SPLUNKUSERNAME=admin SPLUNKPASSWORD="<choose-a-strong-password>" `
  LAUNCHSPLUNK=1 SERVICESTARTTYPE=auto /quiet
```
Replace the password placeholder before running. `/quiet` suppresses all UI — drop it
if you want to watch progress.

## After install — verification (tell me the results, or let me re-check from here)

Once installed, from an elevated or regular shell:
```powershell
Get-Service Splunkd
```
should show `Running`. Then browse to `http://localhost:8000` and confirm the Splunk
Web login page loads.

Once you confirm Splunk Web is up, I'll:
- Set up a dedicated `endpoint` index (Phase 3) via Splunk Web or the CLI.
- Enable the receiving port (9997) so the main PC's forwarder has somewhere to send data.
- Write up `main-pc-scripts/` for Phase 2 (Sysmon + Universal Forwarder on your main PC).

## Status: ⬜ waiting on you to run the install and confirm
