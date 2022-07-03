; (fenced_code_block (info_string) @MDTSFencedCodeBlockInfo) @MDTSFencedCodeBlock
; (fenced_code_block_delimiter) @MDTSFencedCodeBlock
; (
;     (atx_heading (atx_h1_marker) @MDTSHeadlineMarker) @OrgTSHeadlineLevel1
;     (set! "priority" 2050)
; )
; (
;     (atx_heading (atx_h2_marker) @MDTSHeadlineMarker) @OrgTSHeadlineLevel2
;     (set! "priority" 2050)
; )
; (
;     (atx_heading (atx_h3_marker) @MDTSHeadlineMarker) @OrgTSHeadlineLevel3
;     (set! "priority" 2050)
; )
; (
;     (atx_heading (atx_h4_marker) @MDTSHeadlineMarker) @OrgTSHeadlineLevel4
;     (set! "priority" 2050)
; )
; (
;     (atx_heading (atx_h5_marker) @MDTSHeadlineMarker) @OrgTSHeadlineLevel5
;     (set! "priority" 2050)
; )
; (inline_link (link_text) @MDTSLinkText) @MDTSLink

; TODO: https://github.com/akinsho/org-bullets.nvim/blob/main/lua/org-bullets.lua#L167-L188
; handle these conceals with regex matches instead:
((list_marker_star) @conceal (#set! conceal "✸") (#eq? @conceal "* "))
((list_marker_plus) @conceal (#set! conceal "✿") (#eq? @conceal "+ "))
((list_marker_minus) @conceal (#set! conceal "") (#eq? @conceal "- "))
((list_marker_dot) @conceal (#set! conceal "•") (#eq? @conceal ". "))

; ((task_list_marker_checked) @conceal (#set! conceal ""))
; ((task_list_marker_unchecked) @conceal (#set! conceal "☒"))

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
