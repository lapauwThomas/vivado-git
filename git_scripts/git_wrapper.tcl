################################################################################
#
# This file provides a basic wrapper to use git directly from the tcl console in
# Vivado.
# It requires the write_project_tcl_git.tcl script to work properly.
# Unversioned files will be put in the vivado_project folder
#
# Ricardo Barbedo
#
################################################################################

namespace eval ::git_wrapper {
    namespace export git
    namespace export wproj
    namespace import ::custom_projutils::write_project_tcl_git
    namespace import ::current_project
    namespace import ::common::get_property

    proc git {args} {
        set command [lindex $args 0]

        # Change directory project directory if not in it yet
        set proj_dir [regsub {\/vivado_project$} [get_property DIRECTORY [current_project]] {}]
        set current_dir [pwd]
        if {
            [string compare -nocase $proj_dir $current_dir]
        } then {
            puts "Not in project directory"
            puts "Changing directory to: ${proj_dir}"
            cd $proj_dir
        }

        switch $command {
            "init" {git_init {*}$args}
            "commit" {git_commit {*}$args}
            "default" {exec git {*}$args}
        }
    }
	
	proc git_add_hooks {args} {
		set root_dir [exec git rev-parse --show-toplevel]
		set filename  "$root_dir/.git/hooks/pre-commit"
		set fileId [open $filename "w"]

		puts $fileId "#!/bin/sh"
		puts $fileId " #check if commit lock exists and prevent commit"
		puts $fileId " if test -f \"git_vivado_commit_lock\"; then	"
		puts $fileId "    echo \"Please use the Vivado TCL console to commit the project properly.\"  "
		puts $fileId "	  exit 1				"
		puts $fileId " fi 						"
		puts $fileId ""
		close $fileId
	}
	
	proc git_create_vivado_lock {args} {
		set root_dir [exec git rev-parse --show-toplevel]
		set filename  "$root_dir/git_vivado_commit_lock"
		set file [open $filename "w"]
		close $file
	}
	proc git_commit_vivado_unlock {args} {
		set root_dir [exec git rev-parse --show-toplevel]
		set filename_lock  "$root_dir/git_vivado_commit_lock"
		set filename_unlock  "$root_dir/git_vivado_commit_unlock"
		file rename $filename_lock $filename_unlock
	}
	
	proc git_commit_vivado_lock {args} {
		set root_dir [exec git rev-parse --show-toplevel]
		set filename_lock  "$root_dir/git_vivado_commit_lock"
		set filename_unlock  "$root_dir/git_vivado_commit_unlock"
		file rename $filename_unlock $filename_lock
	}

    proc git_init {args} {
        # Generate gitignore file
        if {[catch { file copy -force ./git_scripts/gitignore_base ./.gitignore} err]} {
				puts "error copying gitignore from scripts dir: $err"
                puts "manually creating .gitignore"
                set file [open ".gitignore" "w"]
                puts $file "vivado_project/*              "
                puts $file "git_vivado_commit_lock        "
                puts $file "                              "
                puts $file "vivado_pathfile.txt           "
                puts $file "/vivado*.str                  "
                puts $file "/vivado*.txt                  "
                puts $file "/vivado*.jou                  "
                puts $file "/vivado*.log                  "
                puts $file ".Xil/                         "
                puts $file "NA/                           "
                close $file
		} else {
		   
		}
       

        # Initialize the repo
        exec git {*}$args
        exec git add .gitignore
		git_add_hooks
		git_create_vivado_lock
		puts "Git and project initialized"
    }

	proc git_terminal_editor {args} {
        # gets the git default editor and tries to figure out if its a GUI or terminal program
		set editor_name [exec git config --get core.editor]
        # puts "Getting git editor: $editor_name"
        if { [string match "*vi*" $editor_name] } { return 1 } 	#vi
		if { [string match "*nano*" $editor_name] } { return 1 } 	#nano
		if { [string match "*notepad*" $editor_name] } { return 0 } #notepad
		if { [string match "*code*" $editor_name] } { return 0 } 	#vscode

		
			return 1 
			#unknown
		}

    proc git_commit_wrap {args} {
		
        # Refuse to commit if the "-m" flag is not present, to avoid
        # getting stuck in the Tcl console if a terminal editor is used
		if { [git_terminal_editor] } {
			if { !("-m"  in $args) } {
				send_msg_id Vivado-git-001 ERROR "Please use the -m option to include a message when committing.\n"
				return
			}		
		} else {
                        # puts "Gui editor"
        }

        # Get project name
        set proj_file [current_project].tcl
        # Generate project and add it
        write_project_tcl_git -no_copy_sources -force $proj_file
        puts $proj_file
        exec git add $proj_file

        # Now commit everything
        exec git {*}$args
    }

	 proc git_commit {args} {
		if {[catch {git_commit_vivado_unlock} err]} {
				puts "error removing commit lock: $err"
		} else {
		    puts "Clear commit lock"
		}
		
		if {[catch {git_commit_wrap {*}$args} err]} { 
				puts "error comitting: $err"
		} else {
			puts "Sucessfully committed"
		}
		
		if {[catch {git_commit_vivado_lock} err]} {
				puts "error creating commit lock: $err"
		} else {
		    puts "Reset commit lock"
		}
		
    }

    proc wproj {} {
        # Change directory project directory if not in it yet
        set proj_dir [regsub {\/vivado_project$} [get_property DIRECTORY [current_project]] {}]
        set current_dir [pwd]
        if {
            [string compare -nocase $proj_dir $current_dir]
        } then {
            puts "Not in project directory"
            puts "Changing directory to: ${proj_dir}"
            cd $proj_dir
        }

        # Generate project
        set proj_file [current_project].tcl
        puts $proj_file
        write_project_tcl_git -no_copy_sources -force $proj_file
    }
}
