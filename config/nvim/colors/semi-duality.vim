hi clear
runtime colors/base16-white-on-black.vim

" primary
let p = #{
  \ black: "#000000",
  \ white: "#FFFFFF",
\ }
" accents
let a = #{
  \ cyan: "#00C7F7",
  \ violet: "#AAA9FF",
  \ pink: "#FA86CE",
  \
  \ green: "#11D396",
  \ yellow: "#C7B700",
  \ orange: "#FF9365",
\ }
" oklch 50% lightness - 0.15 chroma
let hint = "#4f3a31"


exe $'hi Visual guibg={a.violet} guifg={p.black}'
exe $'hi! TelescopeSelection guifg={p.violet}'

let g:rainbow_hl = []
for [name, value] in items(a)
  let group = 'SD' . name
  exe $'hi {group} guifg={value}'
  let g:rainbow_hl += [group]
endfor

for level in ["Error", "Warn", "Info", "Hint"]
  for part in ["", "VirtualText", "Floating", "Sign"]
    exe $'hi! Diagnostic{part}{level} guifg={hint}'
  endfor
  exe $'hi! DiagnosticUnderline{level} guisp={hint} guibg={hint}'
endfor

