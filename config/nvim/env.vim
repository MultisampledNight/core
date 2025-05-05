function s:Determine()
  " is this a typst project?
  if $TYPST_ROOT != "" 
    return $TYPST_ROOT
  endif

  let cwd = getcwd()

  if filereadable(".project")
    return cwd
  endif

  " is this a git repo?
  let toplevel = trim(system("git rev-parse --show-toplevel"))
  if v:shell_error == 0
    return toplevel
  endif

  " is this a rust project?
  let toplevel = trim(system("cargo metadata --format-version=1 --offline --no-deps 2>/dev/null"))
  if v:shell_error == 0
    return json_decode(toplevel)["workspace_root"]
  endif

  " fall back to the cwd
  return cwd
endfunction

function ProjectToplevel()
  let g:toplevel = s:Determine()
  return g:toplevel
endfunction

" hacky and bound to interfere with the latex or typst machinery, but it works
function CdProjectToplevel(_timer_id)
  exe "tcd " . ProjectToplevel()
endfunction
autocmd BufEnter * call timer_start(50, "CdProjectToplevel")

silent call ProjectToplevel()

