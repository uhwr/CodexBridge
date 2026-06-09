param(
  [Parameter(Mandatory = $true)]
  [string]$NodeBin,

  [Parameter(Mandatory = $true)]
  [string]$Runner,

  [Parameter(Mandatory = $true)]
  [string]$RootDir,

  [Parameter(Mandatory = $true)]
  [string]$HomeDir,

  [Parameter(Mandatory = $true)]
  [string]$StateDir,

  [Parameter(Mandatory = $true)]
  [string]$EnvFile,

  [Parameter(Mandatory = $true)]
  [string]$StdoutLog,

  [Parameter(Mandatory = $true)]
  [string]$StderrLog,

  [string]$DefaultCwd = ""
)

$ErrorActionPreference = "Stop"

function ConvertTo-WindowsCommandLineArgument([string]$Argument) {
  if ($Argument.Length -eq 0) {
    return '""'
  }

  if ($Argument -notmatch '[\s"]') {
    return $Argument
  }

  $Result = '"'
  $Backslashes = 0
  foreach ($Char in $Argument.ToCharArray()) {
    if ($Char -eq '\') {
      $Backslashes += 1
      continue
    }

    if ($Char -eq '"') {
      $Result += ('\' * ($Backslashes * 2 + 1))
      $Result += '"'
      $Backslashes = 0
      continue
    }

    if ($Backslashes -gt 0) {
      $Result += ('\' * $Backslashes)
      $Backslashes = 0
    }
    $Result += $Char
  }

  if ($Backslashes -gt 0) {
    $Result += ('\' * ($Backslashes * 2))
  }
  $Result += '"'
  return $Result
}

if (-not (Test-Path $NodeBin)) {
  throw "node was not found: $NodeBin"
}
if (-not (Test-Path $Runner)) {
  throw "service runner was not found: $Runner"
}

$NodeArguments = @(
  $Runner,
  "--root-dir", $RootDir,
  "--home-dir", $HomeDir,
  "--state-dir", $StateDir,
  "--env-file", $EnvFile,
  "--stdout-log", $StdoutLog,
  "--stderr-log", $StderrLog
)
if ($DefaultCwd) {
  $NodeArguments += @("--cwd", $DefaultCwd)
}

$StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
$StartInfo.FileName = $NodeBin
$StartInfo.Arguments = ($NodeArguments | ForEach-Object { ConvertTo-WindowsCommandLineArgument $_ }) -join " "
$StartInfo.UseShellExecute = $false
$StartInfo.CreateNoWindow = $true
$StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

$Process = [System.Diagnostics.Process]::Start($StartInfo)
try {
  $Process.WaitForExit()
  exit $Process.ExitCode
} finally {
  if ($Process -and -not $Process.HasExited) {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
  }
}
