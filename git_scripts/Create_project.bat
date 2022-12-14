@echo off
rem start powershell -command "& './git_scripts/Open_project.ps1'"
echo .
echo .
if exist ./git_scripts/Open_project.ps1 (
	Powershell.exe -executionpolicy remotesigned -File  ./git_scripts/Vivado_create_project.ps1
) else (
	if exist ./git_scripts/Open_project.ps1 (
		Powershell.exe -executionpolicy remotesigned -File  ./Vivado_create_project.ps1
	)
)
rem pause