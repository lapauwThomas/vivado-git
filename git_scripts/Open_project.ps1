$vivado_executable_name = "vivado"
$vivado_pathfile_name = "vivado_pathfile.txt"
$scripts_path = ".\git_scripts"
$hooks_file = "pre-commit"

$hooks_dest = ".\.git\hooks\"

$vivado_init_path = "$scripts_path\Vivado_init.tcl"
$project_folder_path = ".\vivado_project"

$git_vivado_lock_name = "git_vivado_commit_lock"

$temp_files_vivado = @( "vivado*.backup.jou" , "vivado*.backup.log", "vivado_*.str")
$temp_folders_vivado = @( ".\.Xil" , ".\NA")


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


function Select-Project-TCL-Path {
    $filenames = @()
    while ($filenames.Length -ne 1) {
        $filenames = @(Get-ChildItem .\ -Filter *.tcl | Out-GridView -OutputMode Single -Title 'Choose a file' )
    }
    return $filenames[0]
}

function New-Vivado-Pathfile {
    New-Item $vivado_pathfile_name | Out-Null
    Set-Content $vivado_pathfile_name 'c:\path\to\vivado\folder\goes\on\first\line\vivado'
    Write-Host "No pathfile found in root. Creating pathfile. Please update the pathfile with your local machine vivado path and run again." -ForegroundColor Red
    Invoke-Item $vivado_pathfile_name
}

function OpenProject {
    if(! (Test-Path -Path $project_folder_path)){
        return -1
    }
    $project = Get-ChildItem -Path $project_folder_path -Filter *.xpr -File | ForEach-Object{$_.FullName}

    if (! (Test-Path -Path $project -PathType Leaf)) {
        return -1
    }
    $args = "-source $vivado_init_path $project"
    Write-Host "Opening existing project at $project"
    Start-Process $local_vivado_path -Argumentlist $args  -WindowStyle Hidden 
    
}
function InitProject{
    if((Test-Path -Path $project_folder_path)){
        Write-Host "Deleting existing project"
        Remove-Item -LiteralPath $project_folder_path -Force -Recurse
    }
    
    Write-Host "Initializing project"
    $args = "-source $vivado_init_path -source $project_tcl"
    Start-Process $local_vivado_path -Argumentlist $args  -WindowStyle Hidden 
    
}

function Clean-Root-Folder {
    Write-Host "Cleaning temp files/folders in root dir"
    foreach ($tempfile in $temp_files_vivado) {
        Get-ChildItem -Filter $tempfile -File | ForEach-Object{Remove-Item -Path $_.FullName}
    }
    foreach ($temp_folder in $temp_folders_vivado) {
        if (Test-Path $temp_folder) {
            Remove-Item -LiteralPath $temp_folder -Force -Recurse
        }
    }
}

function Local-Repo-Is-Initialized {
    if (Test-Path -Path $git_vivado_lock_name -PathType Leaf) {
        return $true
    }
    return $false
}

Clean-Root-Folder

if(! (Local-Repo-Is-Initialized)){
    Write-Host "Local repo not initialized - creating vivado_commit_lock and copying commit hooks"
    New-Item $git_vivado_lock_name | Out-Null #create the lock file
    Robocopy $scripts_path  $hooks_dest $hooks_file /XC /XN /NFL /NDL /NJH /NJS
    # Copy-Item -Path  $hooks_file -Destination $hooks_dest #copy the hooks
}


 
$local_vivado_path = Get-Vivado-Path
if ($null -eq $local_vivado_path) {
    New-Vivado-Pathfile
    pause("Press any key to exit")
    Exit -1
}

#iterate TCL files to find project init TCL. If none, give error. If multiple show selection window.
$tclFiles = @(Get-ChildItem -Path .\ -Filter *.tcl -File -Name)
if ($tclFiles.Count -eq 0) {
    Write-Host "No TCL file found in root." -ForegroundColor Red
    pause("Press any key to exit")
    Exit -1
}

if ( $tclFiles.Count -gt 1) {
    Write-Host "Use the dialog to select the project TCL"
    $project_tcl = Select-Project-TCL-Path
}
else {
    $project_tcl = $tclFiles[0]
}

Write-Host "Using TCL: " $project_tcl


$openmode = 'init'

#check if project folder exists
if (Test-Path -Path $project_folder_path) {

    while ($true) {
        $confirmation = Read-Host "Project exists. [r] for re-initialize, [o] for open, [q] for quit"
        if ($confirmation -eq 'r') {
            $openmode = 'reinit'
            break
        }
        if ($confirmation -eq 'o') {
            $openmode = 'open'
            break
        }
        if ($confirmation -eq 'q') {
            $openmode = 'quit'
            break
        }
    }
}

switch ($openmode) {
    'init' { 
        Write-Host "No project found - creating"
        InitProject
        Break
    }
    'reinit' { 
        InitProject
        Break
    }
    'open' { 
        OpenProject ($project_folder_name)
        Break
    }    
    'quit' { 
        Write-Host "Exiting"
        Exit -1
    }
    Default {
        pause("Wrong input. Any key to exit")
        Exit -1
    }
}

Write-Host "Done"