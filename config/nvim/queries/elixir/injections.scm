; extends

; Documentation
(unary_operator
  operator: "@"
  operand: (call
    target: ((identifier) @_identifier (#any-of? @_identifier "moduledoc" "typedoc" "shortdoc" "doc"))
    (arguments [
      (string (quoted_content) @injection.content)
      (sigil (quoted_content) @injection.content)
    ])
    (#set! injection.language "markdown")))
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

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @heex
(#eq? @_sigil_name "H"))

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

((sigil
   (sigil_name) @_name (#eq? @_name "g")
   (quoted_content) @injection.content
   (sigil_modifiers) @injection.language))

(call (dot left: (atom) @_atom (#eq? @_atom ":esqlite3") right: (identifier) @_identifier (#eq? @_identifier "q")) (arguments (string (quoted_content) @sql))) @foo

; SQL
(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @sql
(#eq? @_sigil_name "Q"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @json
(#eq? @_sigil_name "j"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @elixir
(#any-of? @_sigil_name "q" "S" "E"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "GQL")
 (#set! injection.language "graphql"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "SQL")
 (#set! injection.language "sql"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#any-of? @_sigil_name "LVN" "H")
 (#set! injection.language "heex"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#any-of? @_sigil_name "j" "J" "JSON")
 (#set! injection.language "jsonc"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#any-of? @_sigil_name "RTF")
 (#set! injection.language "heex"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "YAML")
 (#set! injection.language "yaml"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "HTML")
 (#set! injection.language "html"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "ZIG")
 (#set! injection.language "zig"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "r")
 (#set! injection.language "regex"))

(sigil
  (sigil_name) @_sigil_name
  (quoted_content) @injection.content
 (#eq? @_sigil_name "R")
 (#set! injection.language "regex"))


(call target: (identifier) @_script
   (do_block
     (string (quoted_content) @injection.content))
 (#eq? @_script "script")
 (#set! injection.language "javascript"))

(call target: (identifier) @_style
   (do_block
     (string (quoted_content) @injection.content))
 (#eq? @_style "style")
 (#set! injection.language "css"))

; from https://github.com/elixir-tools/elixir-tools.nvim/blob/main/queries/elixir/injections.scm
(call
  target: ((identifier) @_identifier (#eq? @_identifier "execute"))
  (arguments
    (string
      (quoted_content) @sql)))

(call (dot left: (alias) @_alias (#eq? @_alias "Repo") right: (identifier) @_identifier (#eq? @_identifier "query!")) (arguments (string (quoted_content) @sql))) @foo

((call
   target: (dot
             left: (alias) @_mod (#eq? @_mod "EEx")
             right: (identifier) @_func (#eq? @_func "function_from_string"))
   (arguments
     (string
       (quoted_content) @eex))))
