" Settings if running NeoVim's TUI

nnoremap <A-S-j> <Cmd>2split<Enter>z2<Enter><Cmd>term i3status<Enter><Cmd>set nonumber<Enter>G<C-w>j
nnoremap <A-S-f> <Cmd>silent !brightnessctl --exponent set 5\%-<Enter>
nnoremap <A-S-v> <Cmd>silent !brightnessctl --exponent set 3\%+<Enter>
