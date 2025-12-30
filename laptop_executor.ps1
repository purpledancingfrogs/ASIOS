# ASIOS Laptop Mission Executor (repo-rooted, mkdir, no-BOM writes, hash-check)
param([string]$missionPath = "mission_001.json")
$ErrorActionPreference = "Stop"
$repo = (git rev-parse --show-toplevel)

function Abs([string]$p){
  if([System.IO.Path]::IsPathRooted($p)){ return $p }
  return (Join-Path $repo $p)
}
function Sha([string]$p){
  (Get-FileHash -Algorithm SHA256 -Path (Abs $p)).Hash.ToLower()
}
function WriteNoBom([string]$p,[string]$s){
  $ap = Abs $p
  $parent = Split-Path -Parent $ap
  if($parent){ New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [System.IO.File]::WriteAllText($ap, $s, (New-Object System.Text.UTF8Encoding($false)))
}

$mission = Get-Content (Abs $missionPath) -Raw | ConvertFrom-Json

foreach ($step in $mission.payload.steps) {
  $p = [string]$step.path

  if ($step.expected_previous_hash -and (Test-Path (Abs $p))) {
    $cur = Sha $p
    $exp = ([string]$step.expected_previous_hash).ToLower()
    if ($cur -ne $exp) { throw ("Hash mismatch for {0}: expected {1} got {2}" -f $p, $exp, $cur) }
  }

  switch ($step.op) {
    "CREATE_FILE"  { WriteNoBom $p ([string]$step.content) }
    "REPLACE_FILE" { WriteNoBom $p ([string]$step.content) }
    "DELETE_FILE"  { $ap = Abs $p; if (Test-Path $ap) { Remove-Item -Force -Path $ap } }
    "RUN_SCRIPT"   { $ap = Abs $p; if (-not (Test-Path $ap)) { throw ("RUN_SCRIPT not found: {0}" -f $p) }; & $ap; if ($LASTEXITCODE -ne 0) { throw ("RUN_SCRIPT failed ({0}): {1}" -f $LASTEXITCODE, $p) } }
    default        { throw ("Unsupported op: {0}" -f [string]$step.op) }
  }
}

Write-Output ("Mission '{0}' executed." -f $mission.mission_id)