@echo off
chcp 65001 > nul
REM claude-skills setup - junction each skill folder into ~/.claude/skills/
REM Double-click to run. Skips names that already exist. Junctions need no admin rights.
set "SKILLS=%USERPROFILE%\.claude\skills"
if not exist "%SKILLS%" mkdir "%SKILLS%"

for /d %%D in ("%~dp0*") do (
    if /i not "%%~nxD"==".git" (
        if exist "%SKILLS%\%%~nxD" (
            echo SKIP exists: %%~nxD
        ) else (
            mklink /J "%SKILLS%\%%~nxD" "%%~fD" >nul && echo OK: %%~nxD
        )
    )
)
echo.
echo Done. Restart Claude Code to load skills.
pause
