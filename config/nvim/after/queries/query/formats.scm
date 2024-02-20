; Ignore next node with `; format-ignore`
((comment) @_pattern
  .
  (_) @format.ignore
  (#lua-match? @_pattern "^;+%s*format%-ignore"))

; {{{
; Add newlines to top level nodes
; {{{
; Preserve inline comments
(program
  .
  (_)
  (comment) @format.prepend-newline
  (#is-start-of-line? @format.prepend-newline))

(program
  .
  (_)
  (comment) @_comment
  .
  (comment) @format.prepend-newline
  (#not-is-start-of-line? @_comment)
  (#is-start-of-line? @format.prepend-newline))

; }}}
; Making sure all top-level patterns are separated
(program
  (_) @format.append-newline)

(program
  (_) @format.cancel-append .)

(program
  .
  (_)
  [
    (list)
    (grouping)
    (named_node)
    (anonymous_node)
    (field_definition)
  ] @format.prepend-newline)

(program
  (comment) @_comment
  .
  [
    (list)
    (grouping)
    (named_node)
    (anonymous_node)
    (field_definition)
    (comment)
  ] @format.cancel-prepend
  (#is-start-of-line? @_comment))

; }}}
; delims
[
  ":"
  "."
] @format.append-space

("." @format.prepend-space @format.cancel-append
  .
  ")")

; List handler
; Only starts indent if 2 or more elements
(list
  "[" @format.indent.begin
  "]" @format.indent.dedent)

; Otherwise, remove brackets
(list
  "[" @format.remove @format.cancel-append
  .
  (_) @format.cancel-append
  .
  "]" @format.remove)

; [ ... ] @capture1 @capture2
; Append newlines for nodes inside the list
(list
  (_) @format.append-newline
  (#not-has-type? @format.append-newline capture quantifier))

; (_), "_" and _ handler
; Start indents if it's one of these patterns
(named_node
  [
    "_"
    name: (identifier)
  ] @format.indent.begin
  .
  [
    (list) ; (foo [...])
    (grouping) ; (foo ((foo)))
    (negated_field) ; (foo !field)
    (field_definition) ; (foo field: (...))
    (named_node) ; (foo (bar))
    (predicate) ; (named_node (#set!))
    (anonymous_node)
    "."
  ])

; Honoring comment's position within a node
(named_node
  [
    "_"
    name: (identifier)
  ] @format.indent.begin
  .
  (comment) @_comment
  (#is-start-of-line? @_comment))

(named_node
  [
    "_"
    name: (identifier)
  ] @format.indent.begin @format.cancel-append
  .
  "."? @format.prepend-newline
  .
  (comment) @format.prepend-space
  (#not-is-start-of-line? @format.prepend-space))

; Add newlines for other nodes, in case the top node is indented
(named_node
  [
    (list)
    (grouping)
    (negated_field)
    (field_definition)
    (named_node)
    (predicate)
    (anonymous_node)
    "."
  ] @format.append-newline)

; Collapse closing parentheses
(named_node
  [
    "_"
    name: (identifier)
  ]
  (_) @format.cancel-append
  .
  ")"
  (#not-has-type? @format.cancel-append comment))

; All captures should be separated with a space
(capture) @format.prepend-space

; Workaround to just use the string's content
(anonymous_node
  (identifier) @format.keep)

(field_definition
  name: (_)
  ":" @format.indent.begin @format.append-newline ; surpress trailing whitespaces with forced newlines
  [
    (named_node
      [
        (named_node)
        (list)
        (grouping)
        (anonymous_node)
        (field_definition)
      ])
    (list
      "["
      .
      (_)
      .
      (_)
      "]")
    (grouping
      "("
      .
      (_)
      .
      (_)
      ")")
    (grouping
      quantifier: (quantifier))
  ])

; ( (_) ) handler
(grouping
  "("
  .
  [
    (named_node) ; ((foo))
    (list) ; ([foo] (...))
    (anonymous_node) ; ("foo")
    (grouping
      .
      (anonymous_node)) ; (("foo"))
  ] @format.indent.begin
  .
  (_))

(grouping
  "("
  .
  (grouping) @format.indent.begin
  (predicate))

(grouping
  "("
  [
    (anonymous_node)
    (named_node)
    (list)
    (predicate)
    "."
  ] @format.append-newline
  (_) .)

; Collapsing closing parens
(grouping
  (_) @format.cancel-append
  .
  ")"
  (#not-has-type? @format.cancel-append comment))

(grouping
  (capture) @format.prepend-space)

; Remove unnecessary parens
(grouping
  "(" @format.remove
  .
  (_)
  .
  ")" @format.remove .)

(grouping
  "(" @format.remove
  .
  [
    (anonymous_node
      name: (identifier) .)
    (named_node
      [
        "_"
        name: (identifier)
      ] .)
  ]
  .
  ")" @format.remove
  .
  (capture))

(predicate
  (parameters
    (_) @format.prepend-space))

; Workaround to keep the string's content
(string) @format.keep

; Comment related handlers
(comment) @format.append-newline

; comment styling. Feel free to change in the future
((comment) @format.replace
  (#gsub! @format.replace "^;+(%s*.-)%s*$" ";%1"))

; Preserve end of line comments
([
  "."
  ":"
  (list)
  (grouping)
  (named_node)
  (anonymous_node)
  (negated_field)
] @format.cancel-append
  .
  (quantifier)?
  .
  "."? @format.prepend-newline ; Make sure anchor are not eol but start of newline
  .
  (comment) @format.prepend-space
  (#not-is-start-of-line? @format.prepend-space))
