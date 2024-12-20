autocmd BufNewFile,BufRead *.tex
  \ noremap <buffer> <Leader>1 <Cmd>call ViewCurrentPdf()<CR>
  \|noremap <buffer> <Leader>2 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", "-jobname=view", expand("%")])<CR>
autocmd BufEnter *.tex
  \ call ViewCurrentPdf()
autocmd VimLeavePre *.tex
  \ call StopProgram("evince")
