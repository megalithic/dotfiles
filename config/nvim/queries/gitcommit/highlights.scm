; extends

(comment) @comment
(generated_comment) @comment
(title) @text.title
(text) @text
(branch) @text.reference
(change) @keyword
(filepath) @text.uri
(arrow) @punctuation.delimiter

(subject) @text.title
; (subject (overflow) @text)

((subject) @comment.error
  (#vim-match? @comment.error ".\{50,}")
  (#offset! @comment.error 0 50 0 0))

((message_line) @comment.error
  (#vim-match? @comment.error ".\{72,}")
  (#offset! @comment.error 0 72 0 0))

(prefix (type) @keyword)
(prefix (scope) @parameter)
(prefix [
    "("
    ")"
    ":"
] @punctuation.delimiter)
(prefix [
    "!"
] @punctuation.special)

(message) @text

(trailer (token) @keyword)
(trailer (value) @text)

(breaking_change (token) @text.warning)
(breaking_change (value) @text)

(scissor) @comment

(ERROR) @error
