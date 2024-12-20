autocmd BufNewFile,BufRead *.py,*.pyw
  \ nnoremap <Leader>q <Cmd>update \| call jobstart(["black", expand("%")], { "detach": v:false })<CR>
