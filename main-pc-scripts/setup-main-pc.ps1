<#
.SYNOPSIS
  Sets up Sysmon (Olaf Hartong config) + Splunk Universal Forwarder on the main PC,
  pointed at the Splunk indexer running on the other machine.

.NOTES
  Run this in an ELEVATED PowerShell on the MAIN PC (not the Splunk machine).
  EDIT before running:
    - $IndexerAddr : change if the indexer's LAN IP changes

  The forwarder admin password is prompted for at runtime -- nothing to edit for it.

  This script is idempotent-ish but not bulletproof — read it before running rather
  than blindly executing, especially the Sysmon config source (GitHub raw URL).
#>

# ---- EDIT THIS ----
$IndexerAddr = "192.168.1.192:9997"
# --------------------

# Forwarder admin password is prompted for at runtime rather than stored here --
# this file lives in a git repo, so a hardcoded password would get committed.

$ErrorActionPreference = "Stop"
$work = "C:\SIEM-Setup"
New-Item -ItemType Directory -Force -Path $work | Out-Null

Write-Host "== Checking elevation ==" -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Not running elevated. Re-run this script from an Administrator PowerShell."
    exit 1
}

Write-Host "== Checking the indexer is reachable ==" -ForegroundColor Cyan
$idxHost, $idxPort = $IndexerAddr.Split(":")
if (-not (Test-NetConnection -ComputerName $idxHost -Port $idxPort -WarningAction SilentlyContinue).TcpTestSucceeded) {
    Write-Error "Can't reach $IndexerAddr. Check the Splunk machine is powered on, that its inbound firewall rule for $idxPort exists and still matches this machine's IP, and that `$IndexerAddr above is current. Not installing a forwarder pointed at nothing."
    exit 1
}
Write-Host "   $IndexerAddr reachable." -ForegroundColor Green

$secure = Read-Host "Set a password for this forwarder's local admin account" -AsSecureString
$ForwarderPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
if ([string]::IsNullOrWhiteSpace($ForwarderPassword)) {
    Write-Error "Empty password -- aborting."
    exit 1
}

Write-Host "== Downloading Sysmon ==" -ForegroundColor Cyan
$sysmonZip = "$work\Sysmon.zip"
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile $sysmonZip -UseBasicParsing
Expand-Archive -Path $sysmonZip -DestinationPath "$work\Sysmon" -Force

Write-Host "== Downloading Olaf Hartong Sysmon-Modular config ==" -ForegroundColor Cyan
$sysmonConfig = "$work\sysmonconfig.xml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml" -OutFile $sysmonConfig -UseBasicParsing

Write-Host "== Installing Sysmon ==" -ForegroundColor Cyan
& "$work\Sysmon\Sysmon64.exe" -accepteula -i $sysmonConfig
Start-Sleep -Seconds 3
Get-Service Sysmon* | Format-List Name, Status

Write-Host "== Downloading Splunk Universal Forwarder ==" -ForegroundColor Cyan
$ufMsi = "$work\splunkforwarder-10.4.2-windows-x64.msi"
Invoke-WebRequest -Uri "https://download.splunk.com/products/universalforwarder/releases/10.4.2/windows/splunkforwarder-10.4.2-33c3bf42cd73-windows-x64.msi" -OutFile $ufMsi -UseBasicParsing

Write-Host "== Installing Universal Forwarder ==" -ForegroundColor Cyan
$msiArgs = @(
    "/i", "`"$ufMsi`"",
    "AGREETOLICENSE=Yes",
    "SPLUNKUSERNAME=admin",
    "SPLUNKPASSWORD=`"$ForwarderPassword`"",
    "RECEIVING_INDEXER=`"$IndexerAddr`"",
    "WINEVENTLOG_SEC_ENABLE=1",
    "WINEVENTLOG_SYS_ENABLE=1",
    "/quiet"
)
Start-Process msiexec.exe -ArgumentList $msiArgs -Wait

Write-Host "== Dropping in inputs.conf for Sysmon + PowerShell operational logs ==" -ForegroundColor Cyan
$ufHome = "C:\Program Files\SplunkUniversalForwarder"
$localDir = "$ufHome\etc\system\local"
New-Item -ItemType Directory -Force -Path $localDir | Out-Null
Copy-Item -Path "$PSScriptRoot\inputs.conf" -Destination "$localDir\inputs.conf" -Force

Write-Host "== Granting the forwarder's service account read access to protected event channels ==" -ForegroundColor Cyan
# The UF service runs as the virtual account NT SERVICE\SplunkForwarder, which is NOT
# in Event Log Readers by default. Without this, subscribing to the Sysmon operational
# channel (and any other tightly-ACL'd channel) fails silently with errorCode=5
# (Access Denied) in splunkd.log, while looser channels like Security/System still work
# — so the failure is easy to miss until you check sourcetype counts.
Add-LocalGroupMember -Group "Event Log Readers" -Member "NT SERVICE\SplunkForwarder" -ErrorAction SilentlyContinue

Write-Host "== Restarting Splunk Forwarder service ==" -ForegroundColor Cyan
# Restart-Service is avoided here on purpose: splunkd's shutdown routinely outruns the
# default service-control timeout, so Restart-Service reports CouldNotStopService and
# leaves the service STOPPED -- the stop actually succeeded, the start half never ran.
# Stopping and starting as two steps waits properly.
Stop-Service SplunkForwarder -Force
Start-Service SplunkForwarder

Write-Host "== Done. Verify with: Get-Service SplunkForwarder, Sysmon64 ==" -ForegroundColor Green
