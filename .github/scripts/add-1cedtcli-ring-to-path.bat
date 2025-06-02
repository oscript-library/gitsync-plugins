@echo off
setlocal enabledelayedexpansion

:: Search for the 1c-enterprise-ring directory
set "ring_dir="
for /f "delims=" %%d in ('dir /b /ad /o-d "%ProgramFiles%\1C\1CE\components\1c-enterprise-ring-*-x86_64" 2^>nul') do (
    if not defined ring_dir set "ring_dir=%ProgramFiles%\1C\1CE\components\%%d"
)

if not defined ring_dir (
    echo ::error::Could not find ring directory in %ProgramFiles%\1C\1CE\components\
) else (
    echo %ring_dir%>> "%GITHUB_PATH%"
)

:: Search for the 1cedtcli directory (optional)
set "edtcli_dir="
for /f "delims=" %%d in ('dir /b /ad /o-d "%ProgramFiles%\1C\1CE\components\1c-edt-*-x86_64" 2^>nul') do (
    if exist "%ProgramFiles%\1C\1CE\components\%%d\1cedtcli.exe" (
        if not defined edtcli_dir set "edtcli_dir=%ProgramFiles%\1C\1CE\components\%%d"
    )
)

:: Add edtcli_dir to path if found
if not defined edtcli_dir (
    echo ::error::Could not find 1cedtcli directory in %ProgramFiles%\1C\1CE\components\
) else (
    echo %edtcli_dir%>> "%GITHUB_PATH%"
)

echo ::group::Successfully added to PATH
echo %ring_dir%
if defined edtcli_dir echo %edtcli_dir%
echo ::endgroup::
exit /b 0