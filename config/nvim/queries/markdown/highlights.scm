; ; extends

; ; NOTE: It would be nice to prevent conceals in table cells (because they can
; ; mess up pipe alignment) but this is currently impossible since there is no way
; ; to detect if other inline conceals are within table cells because detection is
; ; split among the parsers.
; ; Bullet points
; ([
;   (list_marker_minus)
;   (list_marker_plus)
;   (list_marker_star)
; ] @markup.list
;   (#trim! @markup.list 1 1 1 1)
;   (#set! conceal "•"))

; (list
;   (list_item
;     (list
;       (list_item
;         ([
;           (list_marker_minus)
;           (list_marker_plus)
;           (list_marker_star)
;         ] @markup.list
;           (#trim! @markup.list 1 1 1 1)
;           (#set! conceal "◦"))))))

; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             ([
;               (list_marker_minus)
;               (list_marker_plus)
;               (list_marker_star)
;             ] @markup.list
;               (#trim! @markup.list 1 1 1 1)
;               (#set! conceal "▪"))))))))

; (list
;   (list_item
;     (list
;       (list_item
;         (list
;           (list_item
;             (list
;               (list_item
;                 ([
;                   (list_marker_minus)
;                   (list_marker_plus)
;                   (list_marker_star)
;                 ] @markup.list
;                   (#trim! @markup.list 1 1 1 1)
;                   (#set! conceal "▫"))))))))))

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
;                     ([
;                       (list_marker_minus)
;                       (list_marker_plus)
;                       (list_marker_star)
;                     ] @markup.list
;                       (#trim! @markup.list 1 1 1 1)
;                       (#set! conceal "")))))))))))) ; alts: →

; ; Checkbox list items
; ((task_list_marker_unchecked) @markup.list.unchecked
;   (#offset! @markup.list.unchecked 0 -2 0 0)
;   (#set! conceal "")) ; Alts:✗ ✘ 🗷❌☐

; ((task_list_marker_checked) @markup.list.checked
;   (#offset! @markup.list.checked 0 -2 0 1)
;   (#set! conceal "")) ; Alts:✓ ✔ 🗹✅☑

; (list_item
;   (task_list_marker_checked)
;   (_) @checked.content)

; ; Tables
; (pipe_table_header
;   "|" @punctuation.special
;   (#set! conceal "┃"))

; (pipe_table_delimiter_row
;   "|" @punctuation.special
;   (#set! conceal "┃"))

; (pipe_table_delimiter_cell
;   "-" @punctuation.special
;   (#set! conceal "━"))

; ((pipe_table_align_left) @punctuation.special
;   (#set! conceal "┣"))

; ((pipe_table_align_right) @punctuation.special
;   (#set! conceal "┫"))

; (pipe_table_row
;   "|" @punctuation.special
;   (#set! conceal "┃"))

; ; Block quotes
; ((block_quote_marker) @punctuation.special
;   (#offset! @punctuation.special 0 0 0 -1)
;   (#set! conceal "▐"))

; ((block_continuation) @punctuation.special
;   (#lua-match? @punctuation.special "^>")
;   (#trim! @punctuation.special 1 1 1 1)
;   (#set! conceal "▐"))

; ; Thematic breaks
; ((thematic_break) @punctuation.special
;   (#set! conceal "━"))

; ((thematic_break) @punctuation.special
;   (#offset! @punctuation.special 0 1 0 0)
;   (#set! conceal "━"))

; ((thematic_break) @punctuation.special
;   (#offset! @punctuation.special 0 2 0 0)
;   (#set! conceal "━"))

; (thematic_break) @dash
; (minus_metadata) @dash

; ; Headers
; ((atx_h1_marker) @RenderMarkdownH1 ; @markup.heading.1
;   (#set! conceal "󰉫"))

; ((atx_h2_marker) @RenderMarkdownH2 ; @markup.heading.2
;   (#set! conceal "󰉬"))

; ((atx_h3_marker) @RenderMarkdownH3 ; @markup.heading.3
;   (#set! conceal "󰉭"))

; ((atx_h4_marker) @RenderMarkdownH4 ;  @markup.heading.4
;   (#set! conceal "󰉮"))

; ((atx_h5_marker) @RenderMarkdownH5 ; @markup.heading.5
;   (#set! conceal "󰉯"))

; ((atx_h6_marker) @RenderMarkdownH6 ; @markup.heading.6
;   (#set! conceal "󰉰"))


; ; ((atx_h1_marker) @headline1 (#set! conceal "󰉫")) ; alts: ◉   󰉫¹◉
; ; ((atx_h2_marker) @headline2 (#set! conceal "󰉬")) ; alts: ◆   󰉬²◆
; ; ((atx_h3_marker) @headline3 (#set! conceal "󰉭")) ; alts: 󱄅   󰉭³✿
; ; ((atx_h4_marker) @headline4 (#set! conceal "󰉮")) ; alts: ⭘   󰉮⁴○⭘
; ; ((atx_h5_marker) @headline5 (#set! conceal "󰉯")) ; alts: ◌   󰉯⁵◇◌
; ; ((atx_h6_marker) @headline6 (#set! conceal "󰉰")) ; alts:    󰉰⁶

; ; (atx_heading [
; ;   (atx_h1_marker)
; ;   (atx_h2_marker)
; ;   (atx_h3_marker)
; ;   (atx_h4_marker)
; ;   (atx_h5_marker)
; ;   (atx_h6_marker)
; ; ] @headline)

; ; Ease fenced code block conceals a bit
; ((fenced_code_block_delimiter) @conceal
;   (#set! conceal "~"))

; ; Awesome fenced code block language conceals using Nerd icons
; (fenced_code_block
;   (info_string
;     (language) @label)
;   (#ft-conceal! @label))

; ; Spell checking for table content
; (pipe_table_header
;   (pipe_table_cell) @nospell)

; (pipe_table_row
;   (pipe_table_cell) @spell)


; ; ; extends

; ; ; Headers
; ; ((atx_h1_marker) @headline1 (#set! conceal "󰉫")) ; alts: ◉   󰉫¹◉
; ; ((atx_h2_marker) @headline2 (#set! conceal "󰉬")) ; alts: ◆   󰉬²◆
; ; ((atx_h3_marker) @headline3 (#set! conceal "󰉭")) ; alts: 󱄅   󰉭³✿
; ; ((atx_h4_marker) @headline4 (#set! conceal "󰉮")) ; alts: ⭘   󰉮⁴○⭘
; ; ((atx_h5_marker) @headline5 (#set! conceal "󰉯")) ; alts: ◌   󰉯⁵◇◌
; ; ((atx_h6_marker) @headline6 (#set! conceal "󰉰")) ; alts:    󰉰⁶

; ; (atx_heading [
; ;   (atx_h1_marker)
; ;   (atx_h2_marker)
; ;   (atx_h3_marker)
; ;   (atx_h4_marker)
; ;   (atx_h5_marker)
; ;   (atx_h6_marker)
; ; ] @headline)

; ; ; Thematic breaks
; ; ((thematic_break) @punctuation.special
; ;                   (#offset! @punctuation.special 0 2 0 0)
; ;                   (#set! conceal "━"))
; ; ((thematic_break) @punctuation.special
; ;                   (#offset! @punctuation.special 0 1 0 0)
; ;                   (#set! conceal "━"))
; ; ((thematic_break) @punctuation.special
; ;                   (#set! conceal "━"))

; ; (thematic_break) @dash
; ; (minus_metadata) @dash


; ; ; bullet points
; ;  ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
; ;   @punctuation.special
; ;   (#offset-first-n! @punctuation.special 1)
; ;   (#set! conceal "•"))
; ;  (list
; ;    (list_item
; ;      (list
; ;        (list_item
; ;          ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
; ;           @punctuation.special
; ;           (#offset-first-n! @punctuation.special 1)
; ;           (#set! conceal "∘"))))))
; ;  (list
; ;    (list_item
; ;      (list
; ;        (list_item
; ;          (list
; ;            (list_item
; ;              ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
; ;               @punctuation.special
; ;               (#offset-first-n! @punctuation.special 1)
; ;               (#set! conceal "▪"))))))))
; ;  (list
; ;    (list_item
; ;      (list
; ;        (list_item
; ;          (list
; ;            (list_item
; ;              (list
; ;                (list_item
; ;                  ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
; ;                   @punctuation.special
; ;                   (#offset-first-n! @punctuation.special 1)
; ;                   (#set! conceal "▫"))))))))))
; ;  (list
; ;    (list_item
; ;      (list
; ;        (list_item
; ;          (list
; ;            (list_item
; ;              (list
; ;                (list_item
; ;                  (list
; ;                    (list_item
; ;                      ([(list_marker_minus) (list_marker_plus) (list_marker_star)]
; ;                       @punctuation.special
; ;                       (#offset-first-n! @punctuation.special 1)
; ;                       (#set! conceal "")))))))))))) ; alts: →


; ; ; Checkbox list items
; ; ((task_list_marker_unchecked) @punctuation.special (#offset! @punctuation.special 0 -2 0 0) (#set! conceal "")) ;
; ; ((task_list_marker_checked) @comment (#offset! @comment 0 -2 0 0) (#set! conceal "")) ;
; ; (list_item (task_list_marker_checked)) @comment

; ; ; Tables
; ; (pipe_table_header ("|") @punctuation.special (#set! conceal "┃"))
; ; (pipe_table_delimiter_row ("|") @punctuation.special (#set! conceal "┃"))
; ; (pipe_table_delimiter_cell ("-") @punctuation.special (#set! conceal "━"))
; ; ((pipe_table_align_left) @punctuation.special (#set! conceal "┣"))
; ; ((pipe_table_align_right) @punctuation.special (#set! conceal "┫"))
; ; (pipe_table_row ("|") @punctuation.special (#set! conceal "┃"))

; ; ; Block quotes
; ; ((block_quote_marker) @punctuation.special
; ;                       (#offset! @punctuation.special 0 0 0 -1)
; ;                       (#set! conceal "▐"))
; ; ((block_continuation) @punctuation.special
; ;                       (#lua-match? @punctuation.special "^>")
; ;                       (#offset-first-n! @punctuation.special 1)
; ;                       (#set! conceal "▐"))

; ; ; Ease fenced code block conceals a bit
; ; ((fenced_code_block_delimiter) @punctuation.tilda (#set! conceal ""))
; ; ((fenced_code_block_delimiter) @punctuation.delimiter (#set! conceal ""))
; ; ((fenced_code_block_delimiter) @conceal (#set! conceal ""))

; ; ; Awesome fenced code block language conceals using Nerd icons
; ; ; This solution is a bit hacky to allow the Nerd icon to expand to full width
; ; ; REF: https://github.com/ribru17/.dotfiles/blob/master/.config/nvim/queries/markdown/highlights.scm#L157-L168
; ; (fenced_code_block
; ;   (fenced_code_block_delimiter) @label
; ;   (info_string
; ;     (language) @_lang)
; ;   (#offset! @label 0 1 0 -1)
; ;   (#ft-conceal! @_lang))

; ; ; ((fenced_code_block_delimiter) @label
; ; ;   (#offset! @label 0 2 0 0)
; ; ;   (#set! conceal " "))

; ; (fenced_code_block
; ;   (fenced_code_block_delimiter) @label
; ;   (info_string
; ;     (language) @_lang)
; ;   (#offset! @label 0 2 0 0)
; ;    (#set! conceal ""))

; ; ; Spell checking for table content
; ; (pipe_table_header
; ;   (pipe_table_cell) @nospell)
; ; (pipe_table_row
; ;   (pipe_table_cell) @spell)
