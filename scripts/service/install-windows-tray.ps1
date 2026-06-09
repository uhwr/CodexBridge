param(
  [string]$TaskName = "CodexBridge-Weixin-Tray",
  [string]$BridgeTaskName = "CodexBridge-Weixin",
  [string]$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$StateDir = "",
  [string]$HomeDir = ""
)

$ErrorActionPreference = "Stop"

function Resolve-ServiceHomeDir([string]$RequestedHomeDir, [string]$ResolvedRootDir) {
  if ($RequestedHomeDir) {
    $Resolved = Resolve-Path $RequestedHomeDir -ErrorAction SilentlyContinue
    if ($Resolved) {
      return $Resolved.Path
    }
    return $RequestedHomeDir
  }
  if ($env:USERPROFILE) {
    return $env:USERPROFILE
  }
  $RootMatch = [regex]::Match($ResolvedRootDir, "^[A-Za-z]:\\Users\\[^\\]+")
  if ($RootMatch.Success) {
    return $RootMatch.Value
  }
  throw "Could not resolve home directory. Pass -HomeDir explicitly."
}

$HomeDir = Resolve-ServiceHomeDir $HomeDir $RootDir
if (-not $StateDir) {
  $StateDir = Join-Path $HomeDir ".codexbridge"
}

$TrayScript = Join-Path $RootDir "scripts\service\tray-windows-task.ps1"
if (-not (Test-Path $TrayScript)) {
  throw "Tray script not found: $TrayScript"
}

$PowerShellBin = (Get-Command powershell.exe -ErrorAction Stop).Source
$Arguments = @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-STA",
  "-WindowStyle", "Hidden",
  "-File", "`"$TrayScript`"",
  "-TaskName", "`"$BridgeTaskName`"",
  "-RootDir", "`"$RootDir`"",
  "-StateDir", "`"$StateDir`""
)

$Action = New-ScheduledTaskAction -Execute $PowerShellBin -Argument ($Arguments -join " ")
$CurrentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $CurrentIdentity
$Settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Days 3650) `
  -MultipleInstances IgnoreNew `
  -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId $CurrentIdentity -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "Installed tray scheduled task: $TaskName"
Write-Host "Controls bridge task: $BridgeTaskName"
Write-Host "Root dir: $RootDir"
Write-Host "State dir: $StateDir"
