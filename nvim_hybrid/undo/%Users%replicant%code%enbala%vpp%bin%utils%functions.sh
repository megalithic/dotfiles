Vim�UnDo� �g���P�g�($͕�4��Y�v����5<   _       mix "$(pwd)$script"   @         2       2   2   2    \Sy,    _�                     3       ����                                                                                                                                                                                                                                                                                                                                                             \<�    �   2   4   U      &    section_heading "Running: $script"5�_�                    3        ����                                                                                                                                                                                                                                                                                                                                                             \<�2     �               U       # Echo to stderr   echoerr() {     echo "$@" 1>&2;   }       "# Return the path to the lock file   lock_file() {   3  echo "$(dirname ${BASH_SOURCE[0]})/../setup.lock"   }       # Write the lock file   lock() {   "  if [[ -f "$(lock_file)" ]]; then   3    echo "Error: Another script is already running"   
    exit 1     else       touch "$(lock_file)"     fi   }       # Remove the lock file   
unlock() {     rm -f "$(lock_file)"   }       ?# Prevent the script from running multiple times simultaneously   run_with_lock() {      trap "unlock; exit 1" INT TERM     trap "unlock" EXIT     lock   }       # Print a section heading   section_heading() {     echo     echo "------ $*"   }       run_project_scripts() {     scripts=$*     for script in $scripts; do   &    section_heading "Running: $script"       $script     done   }       run_project_start_scripts() {     scripts=$*     for script in $scripts; do   �    section_heading "=======================================================================================\r\nRunning: $script"   1    # Prefix server output with name of directory   1    dir=$(basename $(dirname $(dirname $script)))   .    $script 2>&1 | sed "s/\(.*\)/[$dir] \1/" &     done     wait   }       )# Run a command in each project directory   run_command_in_projects() {     command=$1     shift   
  paths=$*     for path in $paths; do       (         cd "$path"   2      section_heading "Running in $path: $command"         $command       )     done   }       5# Print message when script exits because of an error   #   
# Example:   #   2#     trap 'error ${BASH_SOURCE[0]} ${LINENO}' ERR   #   	error() {     local parent_filename="$1"     local parent_lineno="$2"     local code="${3:-1}"   c  echoerr "Script failed: Error on or near ${parent_filename}:${parent_lineno}, exit code: ${code}"     exit "${code}"   }5�_�                    .        ����                                                                                                                                                                                                                                                                                                                            (           .           V        \Sue     �   .   /           �   /   7   V    �   /   0   V    �   .   0   V       �   .   0   U    5�_�                    /        ����                                                                                                                                                                                                                                                                                                                            (           .           V        \Sue     �   .   0   \    5�_�                   0        ����                                                                                                                                                                                                                                                                                                                            0          7           V       \Suk    �   /   0          run_project_scripts() {     scripts=$*     for script in $scripts; do   &    section_heading "Running: $script"       $script     done   }    5�_�                    :        ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Suv     �   9   <   V       �   9   ;   U    5�_�      	              ;        ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Suv     �   ;   <           �   <   E   X    �   <   =   X    �   ;   =   X       �   ;   =   W    5�_�      
           	   ;        ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Sux     �   :   ;           5�_�   	              
   ;       ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Suy    �   :   <   ^      run_project_scripts() {5�_�   
                 ;       ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Su�     �   :   <   ^      run_performance_scripts() {5�_�                    ?       ����                                                                                                                                                                                                                                                                                                                            0          0           V       \Su�    �   >   @   ^          $script5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \Sw    �   <   >   _        �   <   >   ^    5�_�                    ?       ����                                                                                                                                                                                                                                                                                                                                                             \Sx<     �   ?   A   `          �   ?   A   _    5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxA     �   <   >   `        echo $scripts5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxC     �   <   >   `        echo "scripts: "$scripts5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxC     �   <   >   `        echo "scripts: "$scripts5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxE     �   <   >   `        echo "scripts: $scripts5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxE     �   <   >   `        echo "scripts: $scripts""5�_�                    =       ����                                                                                                                                                                                                                                                                                                                                                             \SxF     �   <   >   `        echo "scripts: $scripts""5�_�                    @   	    ����                                                                                                                                                                                                                                                                                                                                                             \SxI     �   ?   A   `          echo $script5�_�                    @   	    ����                                                                                                                                                                                                                                                                                                                                                             \SxI     �   ?   A   `      	    echo 5�_�                   A       ����                                                                                                                                                                                                                                                                                                                                                             \Sx]     �   @   B   a          �   @   B   `    5�_�                    A   	    ����                                                                                                                                                                                                                                                                                                                                                             \Sx^     �   @   B   a      	    echo 5�_�                    A       ����                                                                                                                                                                                                                                                                                                                                                             \Sx`     �   @   B   a          echo "$pwd"5�_�                    A       ����                                                                                                                                                                                                                                                                                                                                                             \Sxa     �   @   B   a          echo "$pwd"5�_�                    A       ����                                                                                                                                                                                                                                                                                                                                                             \Sxb     �   @   B   a          echo "$"5�_�                    A       ����                                                                                                                                                                                                                                                                                                                                                             \Sxc    �   @   B   a          echo "$(pwd)"5�_�                    B       ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sxv     �   A   C   a          mix $script�   B   C   a    5�_�                     B   	    ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sxx     �   A   C   a          mix "$script"5�_�      !               B   
    ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sxy     �   A   C   a          mix "$$script"5�_�       "           !   B       ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sxz     �   A   C              mix "$(pwd_)$script"5�_�   !   #           "   B       ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sxz     �   A   C   a          mix "$(pwd_)$script"5�_�   "   $           #   A       ����                                                                                                                                                                                                                                                                                                                            B          B          v       \Sx}     �   @   A              echo "$(pwd)"5�_�   #   %           $   @       ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sx~     �   ?   @              echo "script: $script"5�_�   $   &           %   =       ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sx    �   <   =            echo "scripts: $scripts"5�_�   %   '           &   ?       ����                                                                                                                                                                                                                                                                                                                            ?          ?          v       \Sx�    �   >   @   ^          mix "$(pwd)/$script"5�_�   &   (           '   >       ����                                                                                                                                                                                                                                                                                                                            ?          ?          v       \Sx�     �   >   @   _          �   >   @   ^    5�_�   '   )           (   ?   
    ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sx�     �   >   @   _      
    test=$5�_�   (   *           )   ?   "    ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sx�     �   >   @   _      $    test=$(echo $script | cut -c 5-)5�_�   )   +           *   ?   !    ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sx�     �   ?   A   `          �   ?   A   _    5�_�   *   ,           +   ?       ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sx�     �   >   @   `      $    test=$(echo $script | cut -c 1-)5�_�   +   -           ,   @   	    ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sx�     �   ?   A   `      	    echo 5�_�   ,   .           -   A       ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sx�   	 �   @   B              mix "$(pwd)$script"5�_�   -   /           .   ?   &    ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sy   
 �   >   @   `      )    test_file=$(echo $script | cut -c 1-)5�_�   .   0           /   @       ����                                                                                                                                                                                                                                                                                                                            A          A          v       \Sy     �   ?   @              echo $test_file5�_�   /   1           0   @       ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sy     �   ?   A              # mix "$(pwd)$script"5�_�   0   2           1   @       ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sy    �   ?   A   _          mix "$(pwd)$script"5�_�   1               2   @       ����                                                                                                                                                                                                                                                                                                                            @          @          v       \Sy+    �   ?   A   _          mix "$(pwd)$test_file"5�_�                    A       ����                                                                                                                                                                                                                                                                                                                                                             \Sx[     �   A   B   `          �   A   C   a          echo5�_�                    0       ����                                                                                                                                                                                                                                                                                                                            (           .           V        \Suh     �   /   1   ]      run_perf_scripts() {5��