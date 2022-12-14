@echo off
rem start powershell -command "& './git_scripts/Open_project.ps1'"
echo .
echo .
Powershell.exe -executionpolicy remotesigned -File  ./git_scripts/Open_project.ps1
rem pause