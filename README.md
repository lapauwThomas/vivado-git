# vivado-git
vivado git wrappers and scripts

Modified version from [barbedo/vivado-git](https://github.com/barbedo/vivado-git)

# Changes
 - Added extra powershell scripts (and a .bat to call it) to rebuild the project cleanly from the project TCL.
 - PS script checks path for vivado, or a pathfile in the root of the repo to have a per repository path to vivado
 - Modified the git wrapper such that it adds a pre-commit hook to prevent commits outside of vivado
 - Allow for GUI git commit messages (without -m) switch, by checking the default git editor
 - Wrote a powershell and tcl script to use this repo to create the project structure. Now you can clone this repo, run the script and follow instructions.
 
 # Future enhancements
 - Have the write_project script write the BD tcl as a separate file
