@echo off
setlocal

cd /d "%~dp0"

if not exist "venv\Scripts\python.exe" (
  echo Virtual environment not found at "venv\Scripts\python.exe"
  exit /b 1
)

REM Run ComfyUI with the venv interpreter only
"%~dp0venv\Scripts\python.exe" "%~dp0main.py" ^
  --input-directory "I:\AI\input" ^
  --output-directory "I:\AI\output" ^
  --user-directory "I:\AI\workflows" ^
  --extra-model-paths-config "I:\AI\ComfyUI-Configs\extra_model_paths.yaml" ^
  --enable-manager

endlocal
