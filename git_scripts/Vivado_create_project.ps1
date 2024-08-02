$vivado_executable_name = "vivado"
$vivado_pathfile_name = "vivado_pathfile.txt"
$scripts_path = ".\git_scripts"
$hooks_file = "pre-commit"
$hooks_dest = ".\.git\hooks\"

$vivado_init_path = "$scripts_path\Vivado_init.tcl"
$vivado_project_init_path = "$scripts_path\Vivado_create_project.tcl"

$git_vivado_lock_name = "git_vivado_commit_lock"



$scriptfolder = $PSScriptRoot
Set-Location "$scriptfolder\.."
$CWD = Get-Location
Write-host "Running in $CWD"

Function pause ($message) {
    Write-Host "$message" -ForegroundColor Yellow
    $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Function Get-Folder($initialDirectory) {
    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowserDialog.RootFolder = 'MyComputer'
	$FolderBrowserDialog.Description = 'Navigate to the folder on your disk containing the Vivado binary. Typically this is at C:/Xilinx/Vivado/xx-YOURVERSION-xx/bin/'
    if ($initialDirectory) { $FolderBrowserDialog.SelectedPath = $initialDirectory }
    [void] $FolderBrowserDialog.ShowDialog()
    return $FolderBrowserDialog.SelectedPath
}

function Vivado-From-Pathfile {
	 if ((Test-Path -Path $vivado_pathfile_name -PathType Leaf)) {
        $vivado_path = Get-Content $vivado_pathfile_name
        Write-Host "Vivado from pathfile: " $vivado_path
        if ((Test-Path -Path $vivado_pathfile_name -PathType Leaf)){
            return "$vivado_path\$vivado_executable_name"
        }else{
            Write-Host "Vivado not found in pathfile path. Check and try again" -ForegroundColor Red
            Invoke-Item $vivado_pathfile_name
            return $null
        }
	 }
}

function Get-Vivado-Path {
    if ((Get-Command $vivado_executable_name -ErrorAction SilentlyContinue) ) { 
        $vivado_path = (Get-Command $vivado_executable_name).Path
        Write-host "Vivado found on path at:" $vivado_path
        return $vivado_path
    }
	$path = Vivado-From-Pathfile 
	if ($path ){
		return $path
   

    }else{
        New-Item $vivado_pathfile_name -Force | Out-Null
		Write-Host "No pathfile found in root. Creating pathfile. Navigate to your vivado path (C:/Xilinx ..../20xx.x/bin/)" -ForegroundColor Red
		$selectedPath = Get-Folder('C:\Xilinx\Vivado\')
		Write-Host "SelectedPath = $selectedPath"
        Set-Content $vivado_pathfile_name $selectedPath
		$vivado_path = Vivado-From-Pathfile
		Write-host "Vivado found on path at:" $vivado_path
		return $vivado_path
    }
    return $NULL
}



$local_vivado_path = Get-Vivado-Path
if ($null -eq $local_vivado_path) {
    pause("Press any key to exit")
    Exit -1
}

Write-Host "Deleting existing repo"
Remove-Item -Path ".git" -Force -Recurse -ErrorAction Ignore

Write-Host "Local repo not initialized - creating vivado_commit_lock and copying commit hooks"

New-Item $git_vivado_lock_name -ErrorAction Ignore | Out-Null
Robocopy $scripts_path  $hooks_dest $hooks_file /XC /XN /NFL /NDL /NJH /NJS

Write-Host "Creating project using TCL: " $vivado_project_init_path


Write-Host "Opening vivado and running project script"
$args = "-source $vivado_init_path -source $vivado_project_init_path"
Start-Process $local_vivado_path -Argumentlist $args  -WindowStyle Hidden 



Write-Host "`n`n"
Write-Host "Follow the instructions in the TCL Console (bottom left) to create the project and initialize the repo (you may have to scroll up)" -ForegroundColor Yellow
Write-Host "`n`n"


Robocopy $scripts_path  ".\"  "Open_project.bat" /XC /XN /NFL /NDL /NJH /NJS
Remove-Item -Path "Create_project.bat" -ErrorAction Ignore

Write-Host "Done"

pause("Press any key to exit")