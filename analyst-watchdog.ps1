# Analyst bot watchdog — restarts claude --channels if session is dead or stale
$logFile = "C:\Users\eamon\.claude\channels\telegram\restart.log"
$inboxDir = "C:\Users\eamon\.claude\channels\telegram\inbox"
$staleMinutes = 15

function Write-Log($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg" | Out-File $logFile -Append
}

$claudeRunning = Get-Process -Name "claude" -ErrorAction SilentlyContinue

$staleMessages = Get-ChildItem $inboxDir -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddMinutes(-$staleMinutes) }

if (-not $claudeRunning) {
    Write-Log "Claude process not found — restarting analyst bot."
    Start-Process "claude" -ArgumentList "--channels plugin:telegram@claude-plugins-official"
    Write-Log "Restart triggered."
} elseif ($staleMessages) {
    Write-Log "Stale inbox messages detected (oldest: $($staleMessages | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty LastWriteTime)) — restarting."
    Get-Process -Name "claude" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Start-Process "claude" -ArgumentList "--channels plugin:telegram@claude-plugins-official"
    Write-Log "Restart triggered."
} else {
    Write-Log "Analyst bot healthy — no restart needed."
}
