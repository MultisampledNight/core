autocmd BufNewFile,BufRead *.py
  \ let b:format = {-> jobstart(["black", expand("%")], #{detach: v:false})}
