; extends

((diff) @injection.content
 (#set! injection.combined)
 (#set! injection.language "diff"))

((rebase_command) @injection.content
 (#set! injection.combined)
 (#set! injection.language "git_rebase"))

((subject) @injection.content
  (#set! injection.language "markdown_inline"))

(source
  (subject)
  .
  (message) @injection.content
  (#set! injection.language "markdown")
  (#set! injection.include-children))
