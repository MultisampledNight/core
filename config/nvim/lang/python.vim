autocmd BufNewFile,BufRead *.py,*.pyw
  \ nnoremap <Space>q <Cmd>update \| call jobstart(["black", expand("%")], { "detach": v:false })<CR>
