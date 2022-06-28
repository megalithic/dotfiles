; TODO: https://github.com/akinsho/org-bullets.nvim/blob/main/lua/org-bullets.lua#L167-L188
; handle these conceals with regex matches instead:

((shortcut_link) @conceal (#set! conceal "") (#eq? @conceal "[ ]"))
((shortcut_link) @conceal (#set! conceal "") (#eq? @conceal "[x]"))
