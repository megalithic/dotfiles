;extends
; EXTENDING COMMENTS TAGS https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/comment/highlights.scm
; DOCS https://github.com/nvim-treesitter/nvim-treesitter#adding-queries
;───────────────────────────────────────────────────────────────────────────────

; added by me:
; CONFIG SIC PENDING CAVEAT DATA GUARD SOURCE
; CONFIG: foo PENDING: foo

; original tags:
; FOOBAR TEST ERROR
; NOTE XXX PERF DOCS
; BUG TODO HACK
; BUG: foobar

;───────────────────────────────────────────────────────────────────────────────

[
 "("
 ")"
] @comment.name.bracket

":" @comment.name.delimiter

(tag (user) @comment.name)

("text" @comment.issue (#match? @comment.issue "^#[0-9]+$"))
("text" @comment.user (#match? @comment.user "^[@][a-zA-Z0-9_-]+$"))

((tag ((name) @comment.fix))
 (#any-of? @comment.fix "XXX" "FIX" "FIXME" "FIXIT" "BUG" "ISSUE"))

((tag ((name) @comment.todo))
 (#any-of? @comment.todo "TODO"))

((tag ((name) @comment.hack))
 (#any-of? @comment.hack "HACK"))

((tag ((name) @comment.warn))
 (#any-of? @comment.warn "WARN"))

((tag ((name) @text.warn))
 (#any-of? @text.warn "WARN"))

((tag ((name) @comment.note))
 (#any-of? @comment.note "NOTE" "INFO"))

((tag ((name) @text.ref))
 (#any-of? @text.ref "REF"))

("text" @text.ref
 (#any-of? @text.ref "REF"))

((tag ((name) @text.test))
 (#any-of? @text.test "TEST"))

("text" @text.test
 (#any-of? @text.test "TEST"))


("text" @comment.todo (#any-of? @comment.todo "PENDING" "GUARD" "REQUIRED" "VALIDATE"))
((tag (name) @comment.todo ":" @punctuation.delimiter)
 (#any-of? @comment.todo "PENDING" "GUARD" "REQUIRED" "VALIDATE"))

("text" @comment.note (#any-of? @comment.note "CONFIG" "SOURCE" "DATA" "EXAMPLE"))
((tag (name) @comment.note ":" @punctuation.delimiter)
 (#any-of? @comment.note "CONFIG" "SOURCE" "DATA" "EXAMPLE"))

("text" @comment.warning (#any-of? @comment.warning "SIC" "CAVEAT"))
((tag (name) @comment.warning ":" @punctuation.delimiter)
 (#any-of? @comment.warning "SIC" "CAVEAT"))
