; extends

(string) @nospell

; ((identifier) @variable.builtin
;  (#any-of? @variable.builtin "vim" "bit")
;  (#set! "priority" 128))

((identifier) @variable.builtin
 (#any-of? @variable.builtin "mega" "bit")
 (#set! "priority" 128))

;; extends
(
 (identifier) @variable.builtin
 (#any-of? @variable.builtin "vim")
 (#set! "priority" 128)
)
