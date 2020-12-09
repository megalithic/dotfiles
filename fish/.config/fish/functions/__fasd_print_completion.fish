# suggest paths for current args as completion
function __fasd_print_completion
  set cmd (commandline -po)
  test (count $cmd) -ge 2; and fasd $argv $cmd[2..-1] -l
end
