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

namespace eval ::git_vivado_helper {
    namespace export git_create_project
    namespace export wproj
    namespace import ::custom_projutils::write_project_tcl_git
    namespace import ::current_project
    namespace import ::common::get_property

    proc git_create_project {args} {

        puts ""
        puts ""
        puts ""
        puts ""
        puts "Vivado Git project creator"
        puts "___________________________________________"
        puts ""
        puts "Creating folder structure"
        file mkdir src/HDL
        file mkdir src/SIM
        file mkdir src/constraints
        file mkdir IPs
        file mkdir vivado_project
    	puts ""
        set project_path [file normalize ./vivado_project]
     	send_msg_id Vivado-git-001 WARN "Project needs to be created manually in \"$project_path\"."
        send_msg_id Vivado-git-001 WARN "Use File > Project > New to create it."
        puts ""
        puts ""
        
        send_msg_id Vivado-git-001 WARN "Initialize the repo after creating the project using \"git init\""
        puts ""
        puts "After creating the project, keep the source and IP in their respective folders outside the \"vivado_project\" directory"
        puts "The \"vivado_project\" directory is excluded from the repo"
        puts ""
        puts "DONE" 
    }
 
}

namespace import ::git_vivado_helper::git_create_project
git_create_project
