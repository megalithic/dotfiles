;; extends

; Highlight `command` commands.
; TODO: Remove after PR merge:
; https://github.com/nvim-treesitter/nvim-treesitter/pull/5837
(command
  name: (command_name) @_name
  .
  argument: (word) @function.call
  (#eq? @_name "command"))
