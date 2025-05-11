autocmd BufNewFile,BufRead *.typ
  \ let b:format = {-> jobstart(["typstyle", "--wrap-text", "-i", expand("%")])}
  \|noremap <buffer> <Leader>1 <Cmd>TypstPreviewToggle<Enter>
  \|noremap <buffer> <Leader>9 <Cmd>!flow-export "%"<Enter>
  \|noremap <buffer> <Leader>0 <Cmd>TypstPreviewFollowCursorToggle<Enter>
  \|noremap <buffer> <Leader>z <Cmd>TypstPreviewSyncCursor<Enter>
