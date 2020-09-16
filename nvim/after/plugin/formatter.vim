" --[ formatter definitions (untested) ]---------------------------------------

let s:formatprg_for_filetype = {
      \ "c"          : "uncrustify --l C base kr mb",
      \ "cpp"        : "uncrustify --l CPP base kr mb stroustrup",
      \ "cmake"      : "cmake-format --command-case lower -",
      \ "css"        : "css-beautify -s 2 --space-around-combinator",
      \ "go"         : "gofmt",
      \ "html"       : "tidy -q -w -i --show-warnings 0 --show-errors 0 --tidy-mark no",
      \ "java"       : "uncrustify --l JAVA base kr mb java",
      \ "javascript" : "js-beautify -s 2",
      \ "json"       : "js-beautify -s 2",
      \ "python"     : "autopep8 -",
      \ "sql"        : "sqlformat -k upper -r -",
      \ "xhtml"      : "tidy -asxhtml -q -m -w -i --show-warnings 0 --show-errors 0 --tidy-mark no --doctype loose",
      \ "xml"        : "tidy -xml -q -m -w -i --show-warnings 0 --show-errors 0 --tidy-mark no",
      \}
" \ "elixir"     : "mix format -",

for [ft, fp] in items(s:formatprg_for_filetype)
  execute "autocmd FileType ".ft." let &l:formatprg=\"".fp."\" | setlocal formatexpr="
  " use `gq` from a visual selection, to run the assigned formatter
endfor
