# function fish_prompt
#     switch "$fish_key_bindings"
#         case fish_hybrid_key_bindings fish_vi_key_bindings
#             set STARSHIP_KEYMAP "$fish_bind_mode"
#         case '*'
#             set STARSHIP_KEYMAP insert
#     end
#     set STARSHIP_CMD_STATUS $status
#     # Account for changes in variable name between v2.7 and v3.0
#     set STARSHIP_DURATION "$CMD_DURATION$cmd_duration"
#     starship prompt --status=$STARSHIP_CMD_STATUS --keymap=$STARSHIP_KEYMAP --cmd-duration=$STARSHIP_DURATION --jobs=(count (jobs -p))
# end

# # Disable virtualenv prompt, it breaks starship
# set -g VIRTUAL_ENV_DISABLE_PROMPT 1

# # Remove default mode prompt
# builtin functions -e fish_mode_prompt

# set -gx STARSHIP_SHELL fish

# # Set up the session key that will be used to store logs
# set -gx STARSHIP_SESSION_KEY (random 10000000000000 9999999999999999)

# a called to `_pure_prompt_new_line` is triggered by an event
function fish_prompt
    set --local exit_code $status  # save previous exit code

    echo -e -n (_pure_prompt_beginning)  # init prompt context (clear current line, etc.)
    _pure_print_prompt_rows # manage default vs. compact prompt
    echo -e -n (_pure_prompt $exit_code)  # print prompt
    echo -e (_pure_prompt_ending)  # reset colors and end prompt

    set _pure_fresh_session false
end
