; HTML string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @html))
  (#eq? @_comment "# html"))

; HEEx string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @heex))
  (#eq? @_comment "# heex"))

; JSON string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @json))
  (#eq? @_comment "# json"))

; JavaScript string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @javascript))
  (#eq? @_comment "# javascript"))

; JavaScript string blocks
((comment) @_comment
  .
  (string (quoted_content) @javascript)
  (#eq? @_comment "# javascript"))
