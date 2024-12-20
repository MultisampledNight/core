autocmd BufNewFile,BufRead *.tex
  \ set filetype=latex sw=2 ts=2 sts=0 et
  \|noremap <buffer> <Leader>1 <Cmd>call ViewCurrentPdf()<CR>
  \|noremap <buffer> <Leader>2 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", "-jobname=view", expand("%")])<CR>
autocmd BufEnter *.tex
  \ call ViewCurrentPdf()
autocmd VimLeavePre *.tex
  \ call StopProgram("evince")
