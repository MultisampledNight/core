function CloseIfAlreadyOpen()
  let pidfile = $state_local . "/neovim/editing-in-godot"
  call system("ps -p $(cat " . pidfile . ")")
  if v:shell_error == 0
    " yep, already editing
    exit
  endif

  " oh well then let's propagate that we're currently editing
  call system("mkdir $(dirname " . pidfile . ")")
  call system("echo -n " . getpid() . " > " . pidfile)
endfunction
autocmd VimEnter *.gd
  \ call CloseIfAlreadyOpen()
autocmd BufNewFile,BufRead *.gd
  \ set filetype=gdscript
  \|set updatetime=500
