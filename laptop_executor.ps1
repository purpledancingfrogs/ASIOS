# ASIOS Laptop Mission Executor (deterministic + hash-gated)
param([Parameter(Mandatory=$false)][string]$missionPath = "mission_001.json")

function Get-Sha256Hex([string]$p) {
  return (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLower()
}

if (-not (Test-Path $missionPath)) { throw "Mission file not found: $missionPath" }
$missionJson = Get-Content -Raw -Encoding UTF8 $missionPath
$mission = $missionJson | ConvertFrom-Json

if (-not $mission.payload -or -not $mission.payload.steps) { throw "Invalid mission: missing payload.steps" }

foreach ($step in $mission.payload.steps) {
  if (-not $step.op -or -not $step.path) { throw "Invalid step: missing op/path" }

  $target = $step.path

  # Enforce expected_previous_hash when provided and file exists
  if ($null -ne $step.expected_previous_hash -and $step.expected_previous_hash -ne "" -and (Test-Path $target)) {
    $cur = Get-Sha256Hex $target
    $exp = ($step.expected_previous_hash.ToString()).ToLower()
    if ($cur -ne $exp) { throw "Hash mismatch for $target. expected=$exp got=$cur" }
  }

  # Ensure parent directory exists for file writes
  $parent = Split-Path -Parent $target
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

  switch ($step.op) {
    "CREATE_FILE" {
      if ($null -eq $step.content) { throw "CREATE_FILE requires content: $target" }
      [System.IO.File]::WriteAllText($target, [string]$step.content, (New-Object System.Text.UTF8Encoding($false)))
    }
    "REPLACE_FILE" {
      if ($null -eq $step.content) { throw "REPLACE_FILE requires content: $target" }
      [System.IO.File]::WriteAllText($target, [string]$step.content, (New-Object System.Text.UTF8Encoding($false)))
    }
    "DELETE_FILE" {
      if (Test-Path $target) { Remove-Item -Force $target }
    }
    "RUN_SCRIPT" {
      if (-not (Test-Path $target)) { throw "RUN_SCRIPT target not found: $target" }
      & $target
      if ($LASTEXITCODE -ne 0) { throw "RUN_SCRIPT failed ($LASTEXITCODE): $target" }
    }
    default { throw "Unknown op: $($step.op)" }
  }
}

Write-Output "Mission '$($mission.mission_id)' executed."
