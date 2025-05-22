autocmd BufNewFile,BufRead *.yaml,*.yml
  \ nnoremap <buffer> <leader>z <Cmd>call Reference()<Enter>

function Reference()
  " inserts a hayagriva reference
  let name = trim(input("Name to cite with: "))
  if name == ""
    return
  endif

  let text =<< trim eval YAML

    {name}:
      type: article
      title: TITLE
      url:
        value: URL
        date: {strftime(g:date_format)}
  YAML

  call append(line("$"), text)

  normal Gk$vb
endfunction
