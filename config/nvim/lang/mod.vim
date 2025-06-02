runtime lang/godot.vim
runtime lang/html.vim
runtime lang/java.vim
runtime lang/json.vim
runtime lang/latex.vim
runtime lang/nix.vim
runtime lang/python.vim
runtime lang/rust.vim
runtime lang/typst.vim
runtime lang/yaml.vim

" Shorthands for setting configuration options
" so not everything is repeated in individual files.

" Combines all given dictionaries, flatly.
" Later dictionary keys override previous ones.
function s:merge(...)
  " a:0 is the count of varargs
  " a:1, ..., a:n are the individual varargs
  " a:000 is a list over the same varargs
  if a:0 == 0
    return {}
  endif

  let sum = a:1
  for next in a:000[1:]
    call extend(sum, next, "force")
  endfor
  return sum
endfunction

" convention here is to always use the short form in helper functions
" so the overrides can hit

" Returns options for soft tabs aka spaces for indenting,
" using the given amount of spaces for one indent.
function s:soft(spaces)
  return #{sw: a:spaces, ts: a:spaces, sts: 0, et: v:true}
endfunction

" Returns options for hard tabs, to be displayed as the given amount of
" spaces each.
function s:hard(display)
  return s:merge(s:soft(a:display), #{et: v:false})
endfunction

let cfg = #{
  \ gd: #{ft: "gdscript", updatetime: 500},
  \ html: s:hard(2),
  \ json: s:hard(2),
  \ md: s:merge(s:soft(2), #{tw: 80}),
  \ rust: #{equalprg: "rustfmt", formatprg: "rustfmt"},
  \ sql: s:soft(4),
  \ tex: s:merge(s:soft(2), #{ft: "latex"}),
  \ tmTheme: s:merge(s:soft(2), #{ft: "xml"}),
  \ typ: s:merge(s:soft(2), #{ft: "typst"}),
\ }
let just_ft = ["agda", "kdl", "scm", "nix"]
for name in just_ft
  let cfg[name] = #{ft: name}
endfor

function s:serialize(opts)
  let conv = ""

  for [key, value] in items(a:opts)
    let conv .= " "

    if type(value) == v:t_bool
      if !value
        let conv .= "no"
      endif
      let conv .= key
    else
      let conv .= key . "=" . value
    endif
  endfor

  return conv
endfunction

for [ext, opts] in items(cfg)
  let opts = s:serialize(opts)
  exe $"autocmd BufNewFile,BufRead *.{ext} set {opts}"
endfor
