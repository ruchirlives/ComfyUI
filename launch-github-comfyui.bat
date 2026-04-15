@echo off
setlocal

cd /d "%~dp0"

REM Activate venv
call venv\Scripts\activate.bat

REM Run ComfyUI using venv python
python main.py ^
  --input-directory "I:\AI\input" ^
  --output-directory "I:\AI\output" ^
  --user-directory "I:\AI\workflows" ^
  --extra-model-paths-config "I:\AI\ComfyUI-Configs\extra_model_paths.yaml" ^
  --enable-manager

endlocal