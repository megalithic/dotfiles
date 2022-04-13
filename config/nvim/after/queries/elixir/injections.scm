; HTML string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @html))
  (#eq? @_comment "# html"))


; JSON string blocks
((comment) @_comment
  .
  (binary_operator
    left: (_)
    right: (string (quoted_content) @json))
  (#eq? @_comment "# json"))
