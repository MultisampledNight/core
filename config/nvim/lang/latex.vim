autocmd BufNewFile,BufRead *.tex
  \ noremap <buffer> <Leader>1 <Cmd>call ViewCurrentPdf()<Enter>
  \|noremap <buffer> <Leader>2 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", "-jobname=view", expand("%")])<Enter>
