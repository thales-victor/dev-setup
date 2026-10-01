@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLI DOCKER.ps1"
exit /b %ERRORLEVEL%
