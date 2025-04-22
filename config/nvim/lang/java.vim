autocmd BufNewFile,BufRead *.java
  \ setlocal equalprg=google-java-format
  \|let b:format = {-> jobstart(["google-java-format", "--replace", expand("%")], #{detach: v:false})}
