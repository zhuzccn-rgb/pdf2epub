@echo off
rem Folio · PDF -> EPUB 一键启动 (双击即可)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
pause
