# claude-skills setup
# 각 스킬 폴더를 ~/.claude/skills/ 에 junction으로 연결
# 기존 스킬은 건드리지 않음 (이름 충돌 시 건너뛰고 경고)

$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot
$skillsDir = Join-Path $env:USERPROFILE ".claude\skills"

if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir | Out-Null
    Write-Host "Created: $skillsDir"
}

$created = 0
$skipped = 0
$conflicts = @()

Get-ChildItem $repo -Directory | Where-Object { $_.Name -ne ".git" } | ForEach-Object {
    $linkPath = Join-Path $skillsDir $_.Name
    if (Test-Path $linkPath) {
        $item = Get-Item $linkPath -Force
        if ($item.LinkType -eq "Junction" -and $item.Target -contains $_.FullName) {
            Write-Host "SKIP (already linked): $($_.Name)"
            $skipped++
        } else {
            Write-Warning "CONFLICT: $linkPath already exists. Skipping."
            $conflicts += $_.Name
        }
    } else {
        New-Item -ItemType Junction -Path $linkPath -Target $_.FullName | Out-Null
        Write-Host "OK: $($_.Name)"
        $created++
    }
}

Write-Host ""
Write-Host "Created: $created, Skipped: $skipped, Conflicts: $($conflicts.Count)"
if ($conflicts.Count -gt 0) {
    Write-Host ""
    Write-Warning "Conflicting names — resolve manually then re-run:"
    $conflicts | ForEach-Object { Write-Host "  - $_" }
}
Write-Host ""
Write-Host "Done. Restart Claude Code to load skills."
