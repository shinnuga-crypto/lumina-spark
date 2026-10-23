@echo off
cd /d "%~dp0"
if not exist "%~dp0runtime\Godot.exe" (
  echo Missing runtime\Godot.exe. Keep the complete game folder together.
  pause
  exit /b 1
)
if not exist "%~dp0.godot\imported" (
  echo Preparing game assets for the first launch...
  start "" /wait "%~dp0runtime\Godot.exe" --headless --editor --import --quit --path "%~dp0."
)
start "" "%~dp0runtime\Godot.exe" --path "%~dp0." %*
