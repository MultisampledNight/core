autocmd BufNewFile,BufRead *.typ
  \ noremap <buffer> <Leader>1 <Cmd>TypstPreviewToggle<CR>
  \|noremap <buffer> <Leader>9 <Cmd>!flow-export %<CR>
  \|noremap <buffer> <Leader>0 <Cmd>TypstPreviewFollowCursorToggle<CR>
  \|noremap <buffer> <Leader>z <Cmd>TypstPreviewSyncCursor<CR>
