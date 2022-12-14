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
function Test-FileLock {
    param (
      [parameter(Mandatory=$true)][string]$Path
    )
    $oFile = New-Object System.IO.FileInfo $Path
    if ((Test-Path -Path $Path) -eq $false) {
      return $false
    }
    try {
      $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
      if ($oStream) {
        $oStream.Close()
      }
      return $false
    } catch {
      # file is locked by a process.
      return $true
    }
  }
  
Function pause ($message) {
    Write-Host "$message" -ForegroundColor Yellow
    $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


Write-Host "Cleaning temp files/folders in root dir"
$file_in_use = $false

:Outer foreach ($tempfile in $temp_files_vivado) {
    Get-ChildItem -Filter $tempfile -File | ForEach-Object{
        if (Test-FileLock $_.FullName) {
            $file_in_use = $true
            break Outer
        }
    }
}

if($file_in_use){
    pause ("Certain files are in use. Close programs. Used files will be ignored. Any key to continue")
}

foreach ($tempfile in $temp_files_vivado) {
    Get-ChildItem -Filter $tempfile -File | ForEach-Object{Remove-Item -Path $_.FullName -ErrorAction Ignore}
}
foreach ($temp_folder in $temp_folders_vivado) {
    if (Test-Path $temp_folder) {
        Remove-Item -LiteralPath $temp_folder -Force -Recurse -ErrorAction Ignore
    }
}



$clean = 'n'


while ($true) {
    Write-Host "Run git clean? [yes] to run git clean. Anything else to finish."
    Write-Host "This cannot be undone! Check that everything that should be, is committed" -ForegroundColor Red
        
    $confirmation = Read-Host "Confirm [yes] to run git clean"
    if ($confirmation -eq 'yes') {
        $clean = 'y'
        break
    }
    if ($confirmation -eq 'n') {
        $clean = 'n'
        break
    }
    if ($confirmation -eq 'q') {
        $clean = 'q'
        break
    }
}


switch ($clean) {
    'y' { 
        Write-Host "Running git clean"
        # & git clean -rf
        Break
    }
    'n' { 
        Break
    }
    'q' { 
        Write-Host "Exiting"
        Exit -1
    }
    Default {
        pause("Wrong input. Any key to exit")
        Exit -1
    }
}

Write-Host "Done"