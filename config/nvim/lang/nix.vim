autocmd BufNewFile,BufRead *.typ
  \ let b:format = {-> jobstart(["nixfmt", expand("%")])}
