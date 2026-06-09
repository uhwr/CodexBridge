param(
  [string]$TaskName = "CodexBridge-Weixin",
  [string]$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$StateDir = (Join-Path $env:USERPROFILE ".codexbridge")
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-BridgeTaskState {
  try {
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    $Info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
    return [pscustomobject]@{
      Exists = $true
      State = [string]$Task.State
      LastRunTime = $Info.LastRunTime
      LastTaskResult = $Info.LastTaskResult
      NextRunTime = $Info.NextRunTime
    }
  } catch {
    return [pscustomobject]@{
      Exists = $false
      State = "Missing"
      LastRunTime = $null
      LastTaskResult = $null
      NextRunTime = $null
    }
  }
}

function Get-BridgeIcon($State) {
  if ($State -eq "Running") {
    return [System.Drawing.SystemIcons]::Information
  }
  if ($State -eq "Ready") {
    return [System.Drawing.SystemIcons]::Application
  }
  if ($State -eq "Disabled") {
    return [System.Drawing.SystemIcons]::Warning
  }
  if ($State -eq "Missing") {
    return [System.Drawing.SystemIcons]::Error
  }
  return [System.Drawing.SystemIcons]::Shield
}

function Show-BridgeBalloon($Title, $Text, $Icon = [System.Windows.Forms.ToolTipIcon]::Info) {
  $script:Notify.BalloonTipTitle = $Title
  $script:Notify.BalloonTipText = $Text
  $script:Notify.BalloonTipIcon = $Icon
  $script:Notify.ShowBalloonTip(3000)
}

function Update-BridgeTrayState {
  $State = Get-BridgeTaskState
  $script:LastState = $State
  $script:Notify.Icon = Get-BridgeIcon $State.State
  $script:Notify.Text = "CodexBridge Weixin: $($State.State)"
  $script:StatusItem.Text = "Status: $($State.State)"
  if ($State.LastRunTime) {
    $LastRunText = "Last run: $($State.LastRunTime)"
  } else {
    $LastRunText = "Last run: none"
  }
  $script:LastRunItem.Text = $LastRunText
  $script:LastResultItem.Text = "Last result: $($State.LastTaskResult)"
}

function Invoke-BridgeTaskAction($Action) {
  $Succeeded = $false
  $Message = ""
  $ErrorMessage = ""

  if ($Action -eq "Start") {
    try {
      Start-ScheduledTask -TaskName $TaskName
      $Succeeded = $true
      $Message = "Scheduled task started."
    } catch {
      $ErrorMessage = $_.Exception.Message
    }
  }

  if ($Action -eq "Stop") {
    try {
      Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
      $Succeeded = $true
      $Message = "Scheduled task stopped."
    } catch {
      $ErrorMessage = $_.Exception.Message
    }
  }

  if ($Action -eq "Restart") {
    try {
      Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
      Start-ScheduledTask -TaskName $TaskName
      $Succeeded = $true
      $Message = "Scheduled task restarted."
    } catch {
      $ErrorMessage = $_.Exception.Message
    }
  }

  if ($Succeeded) {
    Show-BridgeBalloon "CodexBridge Weixin" $Message
  } elseif ($ErrorMessage) {
    Show-BridgeBalloon "CodexBridge Weixin" $ErrorMessage ([System.Windows.Forms.ToolTipIcon]::Error)
  }

  Start-Sleep -Milliseconds 500
  Update-BridgeTrayState
}

function Open-BridgeLogsFolder {
  $LogDir = Join-Path $StateDir "logs"
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  Start-Process explorer.exe "`"$LogDir`""
}

function Open-BridgeLogsTail {
  $Script = Join-Path $RootDir "scripts\service\logs-windows-task.ps1"
  if (-not (Test-Path $Script)) {
    Show-BridgeBalloon "CodexBridge Weixin" "Log script not found: $Script" ([System.Windows.Forms.ToolTipIcon]::Error)
    return
  }
  Start-Process powershell.exe -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-NoExit",
    "-File", "`"$Script`"",
    "-StateDir", "`"$StateDir`"",
    "-Follow"
  )
}

function Open-BridgeRepo {
  Start-Process explorer.exe "`"$RootDir`""
}

$script:Notify = New-Object System.Windows.Forms.NotifyIcon
$script:Notify.Visible = $true
$script:Notify.Text = "CodexBridge Weixin"

$Menu = New-Object System.Windows.Forms.ContextMenuStrip

$script:StatusItem = New-Object System.Windows.Forms.ToolStripMenuItem
$script:StatusItem.Enabled = $false
[void]$Menu.Items.Add($script:StatusItem)

$script:LastRunItem = New-Object System.Windows.Forms.ToolStripMenuItem
$script:LastRunItem.Enabled = $false
[void]$Menu.Items.Add($script:LastRunItem)

$script:LastResultItem = New-Object System.Windows.Forms.ToolStripMenuItem
$script:LastResultItem.Enabled = $false
[void]$Menu.Items.Add($script:LastResultItem)

[void]$Menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$RefreshItem = New-Object System.Windows.Forms.ToolStripMenuItem "Refresh status"
$RefreshItem.Add_Click({ Update-BridgeTrayState })
[void]$Menu.Items.Add($RefreshItem)

$StartItem = New-Object System.Windows.Forms.ToolStripMenuItem "Start service"
$StartItem.Add_Click({ Invoke-BridgeTaskAction "Start" })
[void]$Menu.Items.Add($StartItem)

$RestartItem = New-Object System.Windows.Forms.ToolStripMenuItem "Restart service"
$RestartItem.Add_Click({ Invoke-BridgeTaskAction "Restart" })
[void]$Menu.Items.Add($RestartItem)

$StopItem = New-Object System.Windows.Forms.ToolStripMenuItem "Stop service"
$StopItem.Add_Click({ Invoke-BridgeTaskAction "Stop" })
[void]$Menu.Items.Add($StopItem)

[void]$Menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$LogsItem = New-Object System.Windows.Forms.ToolStripMenuItem "Open logs folder"
$LogsItem.Add_Click({ Open-BridgeLogsFolder })
[void]$Menu.Items.Add($LogsItem)

$TailLogsItem = New-Object System.Windows.Forms.ToolStripMenuItem "Follow logs"
$TailLogsItem.Add_Click({ Open-BridgeLogsTail })
[void]$Menu.Items.Add($TailLogsItem)

$RepoItem = New-Object System.Windows.Forms.ToolStripMenuItem "Open project folder"
$RepoItem.Add_Click({ Open-BridgeRepo })
[void]$Menu.Items.Add($RepoItem)

[void]$Menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$ExitItem = New-Object System.Windows.Forms.ToolStripMenuItem "Exit tray icon"
$ExitItem.Add_Click({
  $script:Notify.Visible = $false
  $script:Notify.Dispose()
  [System.Windows.Forms.Application]::Exit()
})
[void]$Menu.Items.Add($ExitItem)

$script:Notify.ContextMenuStrip = $Menu
$script:Notify.Add_DoubleClick({ Open-BridgeLogsTail })

$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 15000
$Timer.Add_Tick({ Update-BridgeTrayState })
$Timer.Start()

Update-BridgeTrayState
Show-BridgeBalloon "CodexBridge Weixin" "Tray controller started."

[System.Windows.Forms.Application]::Run()
