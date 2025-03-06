autocmd BufNewFile,BufRead *.rs
  \ nnoremap <Leader>q <Cmd>update \| call jobstart("cargo fmt")<Enter>
  \|lua require("dap.ext.vscode").load_launchjs(".ide/launch.json")
function RustProjectExecutable()
  let metadata = trim(system("cargo metadata --format-version=1 --offline --no-deps 2>/dev/null"))
  if metadata == ""
    return
  endif
  let metadata = json_decode(metadata)
  let executable = metadata["target_directory"]
    \ . "/debug/"
    \ . metadata["packages"][0]["name"]
  return executable
endfunction
