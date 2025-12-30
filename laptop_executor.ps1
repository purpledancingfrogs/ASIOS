# ASIOS Laptop Mission Executor (hardened)
param([string]$missionPath = "mission_001.json")
$ErrorActionPreference = "Stop"

function Get-SHA256([string]$p){
  (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLower()
}

$mission = Get-Content $missionPath -Raw | ConvertFrom-Json
foreach ($step in $mission.payload.steps) {

  $p = $step.path

  if ($step.expected_previous_hash -and (Test-Path $p)) {
    $cur = Get-SHA256 $p
    $exp = ($step.expected_previous_hash.ToString()).ToLower()
    if ($cur -ne $exp) { throw "Hash mismatch for $p: expected $exp got $cur" }
  }

  if ($p) {
    $parent = Split-Path -Parent $p
    if ($parent -and $parent -ne ".") { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  }

  switch ($step.op) {
    "CREATE_FILE" { Set-Content -Path $p -Value $step.content -Encoding utf8 -NoNewline }
    "REPLACE_FILE" { Set-Content -Path $p -Value $step.content -Encoding utf8 -NoNewline }
    "DELETE_FILE" { if (Test-Path $p) { Remove-Item -Force -Path $p } }
    "INSERT_AFTER_MARKER" {
      if (-not (Test-Path $p)) { throw "INSERT_AFTER_MARKER target not found: $p" }
      $raw = Get-Content $p -Raw
      $marker = $step.marker
      if (-not $marker) { throw "Missing marker for INSERT_AFTER_MARKER" }
      $idx = $raw.IndexOf($marker)
      if ($idx -lt 0) { throw "Marker not found in $p: $marker" }
      $insertPos = $idx + $marker.Length
      $new = $raw.Substring(0, $insertPos) + "
" + $step.content + "
" + $raw.Substring($insertPos)
      Set-Content -Path $p -Value $new -Encoding utf8 -NoNewline
    }
    "RUN_SCRIPT" {
      if (-not (Test-Path $p)) { throw "RUN_SCRIPT not found: $p" }
      & $p
      if ($LASTEXITCODE -ne 0) { throw "RUN_SCRIPT failed ($LASTEXITCODE): $p" }
    }
    default { throw "Unsupported op: $($step.op)" }
  }
}
Write-Output "Mission '$($mission.mission_id)' executed."