autocmd BufNewFile,BufRead *.nix
  \ let b:format = {-> jobstart(["nixfmt", expand("%")])}
