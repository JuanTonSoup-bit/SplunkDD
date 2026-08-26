# Phase 3 — Indexer setup (index + receiving port)

This needs to happen on this machine *before* the main PC's forwarder has anywhere to
send data, so it's pulled forward ahead of Phase 2's writeup. Done via Splunk Web
because it's quick, GUI-based, and avoids putting your Splunk admin password into this
chat/shell.

## 1. Create a dedicated index (don't dump into `main`)

1. Splunk Web (`http://localhost:8000`) → **Settings → Indexes → New Index**
2. Name: `endpoint`
3. Leave other settings default (fine for lab scale) → **Save**

## 2. Enable the receiving port (9997)

1. **Settings → Forwarding and receiving → Configure receiving → New Receiving Port**
2. Port: `9997` → **Save**
3. Confirm: from this machine, `Test-NetConnection localhost -Port 9997` should now
   report `TcpTestSucceeded : True` (I'll re-check from here once you confirm).

## Machine details for Phase 2 (main PC forwarder config)

| | |
|---|---|
| This machine's LAN IP | `192.168.1.192` |
| Receiving port | `9997` (once step 2 above is done) |
| Target index | `endpoint` |

Note: this uses the LAN IP for now since both machines are presumably on the same home
network. Once Tailscale is set up (Phase 5) this could be switched to the Tailscale IP
instead, but there's no need to — 9997 forwarder traffic doesn't need to leave the LAN,
only the Splunk Web UI needs remote access.

## 3. Firewall — inbound rule for 9997 (discovered as a blocker, not originally planned)

This machine's network profile is `Public`, and Windows Firewall had no rule allowing
inbound traffic on 9997 at all — Splunk's installer doesn't create one automatically.
Without this, the main PC's forwarder would connect to nothing and fail silently.

Run **elevated** on this machine, scoped to only the main PC's IP (not open to the
whole LAN):
```powershell
New-NetFirewallRule -DisplayName "Splunk Receiving 9997" -Direction Inbound -LocalPort 9997 -Protocol TCP -Action Allow -RemoteAddress 192.168.1.90 -Profile Any
```
Verified working: `Get-NetTCPConnection -LocalPort 9997` showed an `Established`
connection from `192.168.1.90` once the main PC's forwarder came up.

Same treatment for Splunk Web itself, so it's reachable from the main PC's browser at
`http://192.168.1.192:8000` ahead of Tailscale (Phase 5) being set up:
```powershell
New-NetFirewallRule -DisplayName "Splunk Web 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow -RemoteAddress 192.168.1.90 -Profile Any
```
Verified: rule shows `Profile: Any`, `RemoteAddress: 192.168.1.90`.

## Status: ✅ Done — index created, receiving port open, firewall rule scoped to the main PC's IP, confirmed receiving data (see phase2 doc)
