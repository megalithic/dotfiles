; highlight heredocs in ruby based on the heredoc
; end, for example:
; something(<<-BASH)
; echo "hello world" | rg foobar
; BASH
; will highlight the heredoc content as bash
(
  (heredoc_body
    (heredoc_content) @content
    (heredoc_end) @language
    (#set! "language" @language)
    (#downcase! "language"))
)
