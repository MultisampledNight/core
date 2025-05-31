autocmd BufNewFile,BufRead *.json
  \ let b:format = funcref("FormatJq")

function FormatJq()
  %! jq --sort-keys --indent 2 .
endfunction
