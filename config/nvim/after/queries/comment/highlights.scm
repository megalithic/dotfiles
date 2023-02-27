;; extends

; [
;  "("
;  ")"
; ] @punctuation.bracket

; ; ":" @punctuation.delimiter
; ((tag (name) @TSCommentWarn)
;  (#match? @TSCommentWarn "^(TODO|HACK|WARNING)$"))

; ("text" @TSCommentWarn
;  (#match? @TSCommentWarn "^(TODO|HACK|WARNING)$"))

; ; ((tag (name) @TSCommentFix)
; ;  (match? @TSCommentFix "^(FIX|FIXME|XXX|BUG)$"))

; ; ("text" @TSCommentFix
; ;  (match? @TSCommentFix "^(FIX|FIXME|XXX|BUG)$"))

; ((tag (name) @TSCommentNote)
;  (#match? @TSCommentNote "^(NOTE)$"))

; ("text" @TSCommentNote
;  (#match? @TSCommentNote "^(NOTE)$"))

; ((tag (name) @TSCommentRef)
;  (#match? @TSCommentRef "^(REF)$"))

; ("text" @TSCommentRef
;  (#match? @TSCommentRef "^(REF)$"))


; ("text" @text.danger
;  (#any-of? @text.danger "NOPE" ))

; ("text" @text.danger
;  (#any-of? @text.danger "NOPE" ))

; (tag
;  (name) @ui.text
;  (user)? @constant)

; ; Issue number (#123)
; ("text" @constant.numeric
;  (#match? @constant.numeric "^#[0-9]+$"))

; ; User mention (@user)
; ("text" @tag
;  (#match? @tag "^[@][a-zA-Z0-9_-]+$"))

; (tag ((name) @_name (#match? @_name "TODO") (":" @CommentTasksTodo)))
; (tag ((name) @_name (#match? @_name "FIXME") (":" @CommentTasksFixme)))
; (tag ((name) @_name (#match? @_name "NOTE") (":"  @CommentTasksNote)))
; (tag ((name) @_name (#match? @_name "REF") (":"  @CommentTasksRef)))
; (tag ((name) @_name (#match? @_name "WARN") (":"  @CommentTasksRef)))



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
