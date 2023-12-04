;; extends

; Headers
((atx_h1_marker) @text.title (#set! conceal "¹"))
((atx_h2_marker) @text.title (#set! conceal "²"))
((atx_h3_marker) @text.title (#set! conceal "³"))
((atx_h4_marker) @text.title (#set! conceal "⁴"))
((atx_h5_marker) @text.title (#set! conceal "⁵"))
((atx_h6_marker) @text.title (#set! conceal "⁶"))

(atx_heading [
  (atx_h1_marker)
  (atx_h2_marker)
  (atx_h3_marker)
  (atx_h4_marker)
  (atx_h5_marker)
  (atx_h6_marker)
] @headline)

; Thematic breaks
((thematic_break) @punctuation.special
                  (#offset! @punctuation.special 0 2 0 0)
                  (#set! conceal "━"))
((thematic_break) @punctuation.special
                  (#offset! @punctuation.special 0 1 0 0)
                  (#set! conceal "━"))
((thematic_break) @punctuation.special
                  (#set! conceal "━"))

(thematic_break) @dash
(minus_metadata) @dash

; Ease fenced code block conceals a bit
((fenced_code_block_delimiter) @punctuation.delimiter (#set! conceal "~"))
(fenced_code_block) @codeblock

(block_quote_marker) @quote
(block_quote (paragraph (inline (block_continuation) @quote)))

; TODO: https://github.com/akinsho/org-bullets.nvim/blob/main/lua/org-bullets.lua#L167-L188
; handle these conceals with regex matches instead:
; ; alts: ▪ ●
;
; ((list_marker_star) @conceal (#set! conceal "✸ ") (#eq? @conceal "* "))
; ((list_marker_plus) @conceal (#set! conceal "✿ ") (#eq? @conceal "+ "))
; ; ((list_marker_minus) @conceal (#set! conceal " ") (#eq? @conceal "- "))
; ((list_marker_dot) @conceal (#set! conceal "• ") (#eq? @conceal ". "))
; ; ((task_list_marker_checked) (#set! conceal " ") (#eq? @conceal "- [x] "))
; ; ((task_list_marker_unchecked) (#set! conceal " ") (#eq? @conceal "- [ ] "))
; ((task_list_marker_checked) @conceal (#set! conceal ""))
; ((task_list_marker_unchecked) @conceal (#set! conceal ""))
;
; (list_item [
;   (list_marker_plus)
;   (list_marker_minus)
;   (list_marker_star)
;   (list_marker_dot)
;   (list_marker_parenthesis)
; ] @conceal [
;     (task_list_marker_checked)
;     (task_list_marker_unchecked)
; ](#set! conceal ""))

; bullet points
; ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
;  @punctuation.special
;  (#offset-first-n! @punctuation.special 1)
;  (#set! conceal "•"))
; (list
;   (list_item
;     (list
;       (list_item
;         ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
;          @punctuation.special
;          (#offset-first-n! @punctuation.special 1)
;          (#set! conceal "⭘"))))))
; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
;              @punctuation.special
;              (#offset-first-n! @punctuation.special 1)
;              (#set! conceal "◼"))))))))
; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             (list
;               (list_item
;                 ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
;                  @punctuation.special
;                  (#offset-first-n! @punctuation.special 1)
;                  (#set! conceal "◻"))))))))))
; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             (list
;               (list_item
;                 (list
;                   (list_item
;                     ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
;                      @punctuation.special
;                      (#offset-first-n! @punctuation.special 1)
;                      (#set! conceal "→"))))))))))))
([(list_marker_minus) (list_marker_star)] @punctuation.special (#offset! @punctuation.special 0 0 0 -1) (#set! conceal "•"))

; Checkbox list items
((task_list_marker_unchecked) @punctuation.special (#offset! @punctuation.special 0 -2 0 0) (#set! conceal "")) ;
((task_list_marker_checked) @comment (#offset! @comment 0 -2 0 0) (#set! conceal "")) ;
(list_item (task_list_marker_checked)) @comment

; Use box drawing characters for tables
(pipe_table_header ("|") @punctuation.special @conceal (#set! conceal "┃"))
(pipe_table_delimiter_row ("|") @punctuation.special @conceal (#set! conceal "┃"))
(pipe_table_delimiter_cell ("-") @punctuation.special @conceal (#set! conceal "━"))
(pipe_table_row ("|") @punctuation.special @conceal (#set! conceal "┃"))

; Block quotes
; ((block_quote_marker) @conceal (#set! conceal "▍"))
((block_quote
  (paragraph (inline
    ; (block_continuation) @conceal (#set! conceal "▍")
    (block_continuation) @punctuation.special @conceal (#offset! @punctuation.special 0 0 0 -1) (#set! conceal "▐")
  ))
))
((block_quote_marker) @punctuation.special (#offset! @punctuation.special 0 0 0 -1) (#set! conceal "▐"))
((block_continuation) @punctuation.special (#eq? @punctuation.special "> ") (#offset! @punctuation.special 0 0 0 -1) (#set! conceal "▐"))
((block_continuation) @punctuation.special (#eq? @punctuation.special ">") (#set! conceal "▐"))
(block_quote
  (paragraph) @text.literal)


; (code_span) @nospell

; Needs https://github.com/neovim/neovim/issues/11711
; (fenced_code_block) @codeblock
;
;; extends
