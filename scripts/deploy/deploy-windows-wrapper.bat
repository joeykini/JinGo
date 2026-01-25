@echo off
REM Wrapper script to run PowerShell version with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "%~dp0deploy-windows.ps1" %*
