@echo off
setlocal EnableExtensions

cd /d "%~dp0"

set "PYTHON=%~dp0venv\Scripts\python.exe"
set "UPDATE_REMOTE=upstream"
set "UPDATE_BRANCH=master"
set "TORCH_CONSTRAINTS=%TEMP%\comfyui_torch_constraints_%RANDOM%%RANDOM%.txt"
set "STASHED=0"
set "NEED_STASH=0"
set "STASH_NAME=comfyui-safe-upgrade-%DATE%-%TIME%"
set "STASH_NAME=%STASH_NAME:/=-%"
set "STASH_NAME=%STASH_NAME::=-%"
set "STASH_NAME=%STASH_NAME:.=-%"
set "STASH_NAME=%STASH_NAME: =-%"

echo.
echo === ComfyUI safe upgrade ===
echo Repo: %CD%
echo Source: %UPDATE_REMOTE%/%UPDATE_BRANCH%
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: git was not found in PATH.
  goto :fail
)

if not exist "%PYTHON%" (
  echo ERROR: Virtual environment not found:
  echo   %PYTHON%
  goto :fail
)

if not exist "requirements.txt" (
  echo ERROR: requirements.txt was not found.
  goto :fail
)

echo Current torch packages:
"%PYTHON%" -m pip freeze | findstr /R /I "^torch ^torchvision ^torchaudio ^xformers"
echo.

echo Writing temporary constraints so pip cannot replace torch packages...
"%PYTHON%" -m pip freeze | findstr /R /I "^torch== ^torchvision== ^torchaudio== ^xformers==" > "%TORCH_CONSTRAINTS%"
if errorlevel 1 (
  echo WARNING: No torch constraints were written. Continuing, but check your venv.
) else (
  type "%TORCH_CONSTRAINTS%"
)
echo.

echo Checking git status...
git status --short
echo.

git remote get-url "%UPDATE_REMOTE%" >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git remote "%UPDATE_REMOTE%" was not found.
  echo Existing remotes:
  git remote -v
  goto :fail
)

git diff --quiet --ignore-submodules --exit-code
if errorlevel 1 (
  set "NEED_STASH=1"
)

git diff --cached --quiet --ignore-submodules --exit-code
if errorlevel 1 (
  set "NEED_STASH=1"
)

if "%NEED_STASH%"=="1" (
  echo Stashing tracked local edits before updating...
  git stash push -m "%STASH_NAME%"
  if errorlevel 1 goto :fail_restore
  set "STASHED=1"
  echo.
)

echo Fetching upstream changes...
git fetch --tags "%UPDATE_REMOTE%"
if errorlevel 1 goto :fail_restore

echo Merging %UPDATE_REMOTE%/%UPDATE_BRANCH% into the current branch...
git merge --no-edit "%UPDATE_REMOTE%/%UPDATE_BRANCH%"
if errorlevel 1 goto :fail_restore

echo.
echo Installing ComfyUI requirements with current torch packages constrained...
"%PYTHON%" -m pip install -r requirements.txt -c "%TORCH_CONSTRAINTS%" --upgrade-strategy only-if-needed
if errorlevel 1 goto :fail_restore

if "%STASHED%"=="1" (
  echo.
  echo Restoring stashed local edits...
  git stash pop
  if errorlevel 1 (
    echo.
    echo WARNING: Stash restore had conflicts or could not apply cleanly.
    echo Resolve the conflicts, then run:
    echo   git status
    goto :fail
  )
)

echo.
echo Torch packages after upgrade:
"%PYTHON%" -m pip freeze | findstr /R /I "^torch ^torchvision ^torchaudio ^xformers"
echo.

if exist "%TORCH_CONSTRAINTS%" del "%TORCH_CONSTRAINTS%" >nul 2>nul

echo Safe upgrade complete.
pause
exit /b 0

:fail_restore
echo.
echo ERROR: Upgrade failed.
if "%STASHED%"=="1" (
  echo Your local edits were stashed as:
  echo   %STASH_NAME%
  echo To restore them manually, run:
  echo   git stash list
  echo   git stash pop
)

:fail
if exist "%TORCH_CONSTRAINTS%" del "%TORCH_CONSTRAINTS%" >nul 2>nul
echo.
echo Upgrade did not complete.
pause
exit /b 1
