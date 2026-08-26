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

## Status: ⬜ waiting on you to do steps 1–2 in Splunk Web, then confirm
