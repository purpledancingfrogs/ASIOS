# ASIOS Laptop Mission Executor
param([string]$missionPath = "mission_001.json")

$mission = Get-Content $missionPath | ConvertFrom-Json
foreach ($step in $mission.payload.steps) {
    switch ($step.op) {
        "CREATE_FILE" {
            Set-Content -Path $step.path -Value $step.content
        }
        "REPLACE_FILE" {
            if (Test-Path $step.path) {
                Set-Content -Path $step.path -Value $step.content
            }
        }
        "DELETE_FILE" {
            if (Test-Path $step.path) {
                Remove-Item -Path $step.path
            }
        }
    }
}
Write-Output "Mission '$($mission.mission_id)' executed."
