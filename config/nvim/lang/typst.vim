autocmd BufNewFile,BufRead *.typ
  \ set filetype=typst sw=2 ts=2 sts=0 et
  \|noremap <buffer> <Leader>1 <Cmd>TypstPreviewToggle<CR>
  \|noremap <buffer> <Leader>0 <Cmd>TypstPreviewFollowCursorToggle<CR>
