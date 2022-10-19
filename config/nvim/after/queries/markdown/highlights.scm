;; extends

(atx_heading [
  (atx_h1_marker)
  (atx_h2_marker)
  (atx_h3_marker)
  (atx_h4_marker)
  (atx_h5_marker)
  (atx_h6_marker)
] @headline)

(thematic_break) @dash
(minus_metadata) @dash

(fenced_code_block) @codeblock

(block_quote_marker) @quote
(block_quote (paragraph (inline (block_continuation) @quote)))

; TODO: https://github.com/akinsho/org-bullets.nvim/blob/main/lua/org-bullets.lua#L167-L188
; handle these conceals with regex matches instead:

; alts: ▪ ●

((list_marker_star) @conceal (#set! conceal "✸ ") (#eq? @conceal "* "))
((list_marker_plus) @conceal (#set! conceal "✿ ") (#eq? @conceal "+ "))
((list_marker_minus) @conceal (#set! conceal " ") (#eq? @conceal "- "))
((list_marker_dot) @conceal (#set! conceal "• ") (#eq? @conceal ". "))

(list_item [
  (list_marker_plus)
  (list_marker_minus)
  (list_marker_star)
  (list_marker_dot)
  (list_marker_parenthesis)
] @conceal [
    (task_list_marker_checked)
    (task_list_marker_unchecked)
](#set! conceal ""))

((task_list_marker_checked) @conceal (#set! conceal ""))
((task_list_marker_unchecked) @conceal (#set! conceal ""))
