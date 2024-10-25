colorscheme base16-white-on-black

set winblend=10
set pumblend=10

set termguicolors
set guifont=JetBrainsMonoNL_NF_Light:h14
set linespace=4
set number
set noshowmode
set breakindent
set signcolumn=yes
set title
set titlestring=%m%h%w%F
set titlelen=0
set linebreak
set undofile
set shortmess+=W
set notimeout
set nottimeout
set noequalalways

set clipboard+=unnamedplus
set completeopt=menu,menuone,preview,noselect
set mouse=a
set mousemodel=extend
set mousescroll=ver:4,hor:0
set ignorecase
set smartcase
set scrolloff=2
set sidescrolloff=6
set tabstop=4

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set nofoldenable

let mapleader = " "
let localleader = " "


function SelectionToClipboard()
  if mode() == "v"
    let selection_start = getcurpos()[1:]
    silent normal! o
    let selection_end = getcurpos()[1:]

    silent normal! "*y

    call cursor(selection_start)
    silent normal! v
    call cursor(selection_end)
    silent normal! o
  endif
endfunction

" copy selection to primary clipboard
vnoremap <LeftRelease> <Cmd>call SelectionToClipboard()<cr>

" if you should ever wonder why these shortcuts seem like they're thrown
" all over the place: they're made for the Bone layout, not Qwerty
tnoremap <A-Esc> <C-\><C-N>

nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap gn n<Cmd>noh<CR>
nnoremap gN N<Cmd>noh<CR>

vnoremap j gj
vnoremap k gk
vnoremap gn n<Cmd>noh<CR>
vnoremap gN N<Cmd>noh<CR>

function TelescopeOnToplevel(command)
  silent update
  exe "Telescope " . a:command . " cwd=" . ProjectToplevel()
endfunction

function CreateNewFile()
  let sub_path = trim(input("New file name: ", expand("<cword>")))
  if sub_path == ""
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "edit " . full_path
  write
endfunction

function RenameCurrentFile()
  let old = expand("%:t")
  let sub_path = trim(input("Rename to: ", old))
  if sub_path == ""
    return
  elseif sub_path == old
    echo "Already named that way"
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "saveas " . full_path

  exe "silent !rm " . old
endfunction

nnoremap <Space><Space> <Cmd>Telescope resume<CR>
nnoremap <Space>f <Cmd>call TelescopeOnToplevel("find_files follow=true")<CR>
nnoremap <Space>/ <Cmd>call TelescopeOnToplevel("live_grep")<CR> 
nnoremap gd <Cmd>call TelescopeOnToplevel("lsp_definitions")<CR>
nnoremap gu <Cmd>call TelescopeOnToplevel("lsp_references")<CR>
nnoremap <Space>i <Cmd>call TelescopeOnToplevel("lsp_implementations")<CR>

nnoremap <Space>o <Cmd>Trouble diagnostics toggle filter.severity = vim.diagnostic.severity.ERROR<CR>
nnoremap <Space>x <Cmd>Trouble diagnostics toggle filter.severity.min = vim.diagnostic.severity.WARN<CR>
nnoremap <Space>b <Cmd>update \| Trouble diagnostics<CR>

nnoremap <Space>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
vnoremap <Space>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
nnoremap <Space>r <Cmd>update \| lua vim.lsp.buf.rename()<CR>
nnoremap <Space>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
vnoremap <Space>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
nnoremap <Space>g <Cmd>call TelescopeOnToplevel("lsp_workspace_symbols")<CR>

nnoremap <Space>s <Cmd>call TelescopeOnToplevel("lsp_document_symbols")<CR>
nnoremap <Space>l <Cmd>call TelescopeOnToplevel("treesitter")<CR>
nnoremap <Space>m <Cmd>call TelescopeOnToplevel("man_pages")<CR>
nnoremap <Space>w <Cmd>call TelescopeOnToplevel("keymaps")<CR>

nnoremap <Space>. <Cmd>call TelescopeOnToplevel("git_status")<CR>
nnoremap <Space>j <Cmd>call CreateNewFile()<CR>
nnoremap <Space>c <Cmd>call RenameCurrentFile()<CR>

nnoremap <Space>q <Cmd>update \| call jobstart("cargo fmt")<CR>

nnoremap <Space>z <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap <Space>v <Cmd>lua require("dap").step_over()<CR>
nnoremap <Space>ü <Cmd>lua require("dap").step_into()<CR>
nnoremap <Space>ä <Cmd>lua require("dap").step_out()<CR>
nnoremap <Space>ö <Cmd>lua require("dap").continue()<CR>
nnoremap <Space>y <Cmd>lua require("dap").terminate()<CR>
nnoremap <Space>k <Cmd>lua require("dapui").toggle()<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_refresh_rate_idle = 5
let g:neovide_cursor_unfocused_outline_width = 0.025
let g:neovide_cursor_animation_length = 0.08
let g:neovide_floating_blur_amount_x = 16.0
let g:neovide_floating_blur_amount_y = 16.0
let g:neovide_floating_shadow = v:true
let g:neovide_light_angle_degrees = 40
let g:neovide_light_radius = 10
let g:neovide_underline_automatic_scaling = v:true
let g:neovide_underline_stroke_scale = 2
let g:neovide_hide_mouse_when_typing = v:true

" imports
runtime env.vim
runtime notes.vim
runtime output/mod.vim

" abbreviations for typst and markdown
function SetupAbbrevs()
  let abbrevs = {
    \ "=>":  "⇒",
    \ "<=":  "⇐",
    \ "==>": "⟹",
    \ "<=>": "⇔",
    \ "->":  "→",
    \ "<-":  "⟵",
    \ "<->": "⟷",
    \ "|->": "⟼",
    \ "<-|": "⟻",
    \ "|=>": "⟾",
    \ "<=|": "⟽",
    \
    \ "lra": "⟶",
    \ "sea": "↘",
    \ "swa": "↙",
    \ "nwa": "↖",
    \ "nea": "↗",
    \
    \ "rra": "→",
    \ "dda": "↓",
    \ "lla": "←",
    \ "uua": "↑",
    \
    \ "cbl": "```<CR>```<Esc>kA",
    \ "mk": "$$<Esc>i",
    \ "dm": "$<CR><CR>$<Esc>ki",
    \
    \ "--": "–",
    \ "---": "—",
    \
    \ "@a": "α ",
    \ "@b": "β ",
    \ "@c": "χ ",
    \ "@d": "δ ",
    \ ":d": "∂ ",
    \ "@D": "Δ ",
    \ "@e": "ϵ ",
    \ ":e": "ε ",
    \ "@g": "γ ",
    \ "@k": "κ ",
    \ "@l": "λ ",
    \ "@L": "Λ ",
    \ "@m": "μ ",
    \ "@o": "ω ",
    \ "@O": "Ω ",
    \ "@r": "ρ ",
    \ "@s": "σ ",
    \ "@S": "Σ ",
    \ "@t": "θ ",
    \ "@T": "Θ ",
    \ "@u": "τ ",
    \ "@z": "ζ ",
    \
    \ "NN": "bb(N)",
    \ "QQ": "bb(Q)",
    \ "RR": "bb(R)",
    \ "CC": "bb(C)",
    \
    \ "lor": "∨",
    \ "land": "∧",
    \ "lxor": "⊻",
    \ "neg ": "¬",
    \
    \ "o+": "⊕",
    \ "o×": "⊗",
    \
    \ "andd": "∩",
    \ "orr": "∪",
    \ "sus": "⊂",
    \ "nsus": "⊂",
    \ "inn": "∈",
    \ "nin": "∉",
    \
    \ "sim": "~",
    \ "deg": "°",
    \
    \ "ooo": "∞",
    \
    \ "faal": "∀",
    \ "exs": "∃",
    \
    \ "pm": "plus.minus",
    \
    \ "prl": "∥",
    \ "nprl": "∦",
    \ "btt": "⊥",
    \
    \ "~~~": "≈",
    \ "=~": "≈",
    \ "===": "≡",
    \ "!=": "≠",
    \
    \ "timm": "·",
    \ "xx": "×",
    \
    \ "teq": "≜",
    \ "Tri": "△",
    \ "Ci": "○",
    \ "Sq": "□",
    \
    \ "//": Frac("()", "()"),
    \ "tfr": Frac('""', '""'),
    \ "efr": Frac("^(", ")"),
    \
    \ "prt": Frac("partial ", "partial "),
    \ "pr2": Frac("partial^2 ", "partial^2 "),
    \ "pr3": Frac("partial^3 ", "partial^3 "),
    \
    \ "itg": "integral ~d x<Esc>F~i",
    \
    \ "acc": Fn("accent"),
    \ "ora": "accent(, arrow)<Esc>f,i",
    \
    \ "hatt": "accent(, hat)<Esc>f,i",
    \ "dott": "accent(, dot)<Esc>f,i",
    \ "ddot": "accent(, dot.double)<Esc>f,i",
    \ "dddot": "accent(, dot.triple)<Esc>f,i",
    \ "ddddot": "accent(, dot.quad)<Esc>f,i",
    \
    \ "d1ot": "accent(, dot)<Esc>f,i",
    \ "d2ot": "accent(, dot.double)<Esc>f,i",
    \ "d3ot": "accent(, dot.triple)<Esc>f,i",
    \ "d4ot": "accent(, dot.quad)<Esc>f,i",
    \
    \ "invs": "^(-1)",
    \ "sr": "^2",
    \ "cb": "^3",
    \ "tsa": "^4",
    \ "rd": "^()<Esc>i",
    \
    \ "sts": "_\"\"<Esc>i",
    \ "idd": "_()<Esc>i",
  \ }

  " normal, un-pre-filled functions
  let simple_funcs = #{
    \ vc: "vec",
    \
    \ cnc: "cancel",
    \ acc: "accent",
    \
    \ abs: "abs",
    \ nrm: "norm",
    \ eil: "ceil",
    \ flr: "floor",
    \ rnd: "round",
    \
    \ bb: "bb",
    \ cal: "cal",
    \
    \ sqr: "sqrt",
    \ esq: "root",
  \ }
  " ones that need to be duplicated for under/over variants
  let overunder = #{
    \ vl: "line",
    \ vk: "bracket",
    \ be: "brace",
  \ }
  call map(overunder, {short, long -> extend(
    \ simple_funcs,
    \ {
      \ "o" . short: "over" . long,
      \ "u" . short: "under" . long,
    \ },
  \ )})
  " matrices
  let matrices = #{
    \ p: v:null,
    \ k: "[",
    \ b: "{",
    \ v: "|",
    \ d: "||",
  \ }
  let MaybeArg = {
    \ ch -> ch != v:null
    \ ? '<CR>  delim: "' . ch . '",'
    \ : ""
  \ }
  call map(matrices, {short, delim -> extend(
    \ abbrevs,
    \ { short . "mat": $"mat({MaybeArg(delim)}<CR><CR>)<Esc>kS  " },
  \ )})

  " merge them all
  call extend(abbrevs, map(simple_funcs, {_, long -> Fn(long)}))


  for [short, long] in items(abbrevs)
    exe "inoremap <silent> <buffer> "
      \. Literalize(short, "aggressive")
      \. " "
      \. Literalize(long, "calm")
  endfor
endfunction

function Literalize(seq, mode)
  " this is terrible but i could not think of anything better
  let Aggressive = {_, ch -> get({
    \ "<": "<lt>",
    \ "\\": "<Bslash>",
    \ "|": "<Bar>",
    \ " ": "<Space>",
  \ }, ch, ch)}
  let Calm = {_, ch -> get({
    \ "|": "<Bar>",
    \ " ": "<Space>",
  \ }, ch, ch)}

  if a:mode == "aggressive"
    return map(a:seq, Aggressive)
  else
    return map(a:seq, Calm)
  endif
endfunction

function Fn(name)
  return $"{a:name}()<Esc>i"
endfunction
function Frac(a, b)
  return $"{a:a}/{a:b}<Esc>{len(a:b) + 1}hi"
endfunction

" godot
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

" rust
autocmd BufNewFile,BufRead *.rs set equalprg=rustfmt formatprg=rustfmt
autocmd BufNewFile,BufRead *.rs lua require("dap.ext.vscode").load_launchjs(".ide/launch.json")
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

" markdown
autocmd BufNewFile,BufRead *.md set tw=80 sw=2 ts=2 sts=0 et

" agda
autocmd BufNewFile,BufRead *.agda set ft=agda

" python
autocmd BufWritePost *.py,*.pyw call jobstart(["black", expand("%")], { "detach": v:false })

" sql
autocmd BufNewFile,BufRead *.sql set sw=4 ts=4 sts=0 et

" kdl
autocmd BufNewFile,BufRead *.kdl set ft=kdl

" scm (treesitter queries)
autocmd BufNewFile,BufRead *.scm set ft=scm

" html
autocmd BufNewFile,BufRead *.html set ts=2 sw=2 noet

" latex
autocmd BufNewFile,BufRead *.tex
  \ set filetype=latex sw=2 ts=2 sts=0 et
  \|noremap <buffer> <Leader>1 <Cmd>call ExecAtFile(["pdflatex", "-halt-on-error", "-jobname=view", expand("%")])<CR>
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd VimLeavePre *.tex
  \ call StopProgram("evince")

" typst
autocmd BufNewFile,BufRead *.typ
  \ set filetype=typst sw=2 ts=2 sts=0 et
  \|call LaunchProgram("typst" . bufnr(), [
    \ "typst",
    \ "watch",
    \ "--input", "dev=true",
    \ "--input", "filename=" . expand("%:t"),
    \ "--root", ProjectToplevel(),
    \ expand("%:p"),
    \ CurrentPdfPath(),
  \ ])
  \|noremap <buffer> <Leader>2 <Cmd>call ViewCurrentPdf()<CR>
autocmd BufLeave *.typ
  \ call StopProgram("typst" . bufnr())
autocmd VimLeavePre *.typ
  \ call StopProgram("typst" . bufnr())
  \|call StopProgram("evince")

" both latex and typst, and anything that would require a pdf
autocmd BufEnter *.tex,*.typ call ViewCurrentPdf()
let g:tracked_programs = {}

function CurrentPdfPath()
  return expand("%:p:h") . "/view.pdf"
endfunction

function ViewCurrentPdf()
  if !has_key(g:tracked_programs, "evince")
    echo CurrentPdfPath()
    call LaunchProgram("evince", ["evince", CurrentPdfPath()])
    return
  endif

  try
    let pid = jobpid(g:tracked_programs["evince"])
  catch /.*E900: Invalid channel id/
    call LaunchProgram("evince", ["evince", CurrentPdfPath()])
    return
  endtry
endfunction

function LaunchProgram(name, command)
  " stop previously open from "older" buffer
  call StopProgram(a:name)
  let g:tracked_programs[a:name] = ExecAtFile(a:command)
endfunction

function StopProgram(name)
  if has_key(g:tracked_programs, a:name)
    call jobstop(g:tracked_programs[a:name])
    unlet g:tracked_programs[a:name]
  endif
endfunction

function ExecAtFile(command)
  silent update

  exe "lcd " . expand("%:p:h")
  let job_id = jobstart(a:command, { "detach": v:true })
  lcd -

  return job_id
endfunction

" optional helper commands, if sensible for the current buffer
let s:autowrite = v:false
function AutoWriteToggle()
  call AutoWrite(!s:autowrite)
endfunction
function AutoWrite(target)
  if a:target == s:autowrite
    " no change needed
    return
  endif
  let s:autowrite = !s:autowrite

  augroup autowrite

    au!
    if a:target
      au CursorHold,CursorHoldI * call UpdateIfPossible()
    endif

  augroup END
endfunction

function UpdateIfPossible()
  if &buftype == ""
    silent update
  endif
endfunction

command AutoWriteToggle call AutoWriteToggle()
command AutoWrite call AutoWrite(v:true)
command AutoWriteDisable call AutoWrite(v:false)
autocmd FocusGained * checktime


" some hi magic since base16's vim theme isn't quite there and I'm too lazy to
" change that
for level in ["Error", "Warn", "Info", "Hint"]
  for part in ["", "VirtualText", "Floating", "Sign"]
    exe "hi! Diagnostic" . part . level . " guifg=#001E1B"
  endfor
  exe "hi! DiagnosticUnderline" . level . " guisp=#003833 guibg=#003833"
endfor

lua <<EOF

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

flags = { debounce_text_changes = 150 }

lspconfig.util.default_config = vim.tbl_extend(
  "force",
  lspconfig.util.default_config,
  {
      handlers = {
        ["window/showMessage"] = function(err, method, params, client_id) end;
      }
  }
)

lspconfig.gdscript.setup {}
lspconfig.ruff_lsp.setup {}
lspconfig.rust_analyzer.setup {
  capabilities = capabilities,
  flags = flags,
  filetypes = {
    "rust",
    "netrw",
  },
  settings = {
    ["rust-analyzer"] = {
      imports = {
        granularity = {
          group = "crate",
        },
      },
      checkOnSave = {
        command = "clippy",
      },
    }
  }
}
lspconfig.texlab.setup {
  capabilities = capabilities,
  flags = flags,
  filetypes = {
    "latex",
  },
}
lspconfig.tsserver.setup {}
-- lspconfig.typst_lsp.setup {}

require("trouble").setup({
  open_no_results = true,
  focus = true,
  filter = {
  },
  win = {
    position = "bottom",
    height = 9,
  }
})

require("nvim-treesitter.configs").setup {
  highlight = {
    enable = true,
  },
}

require("treesitter-context").setup {
  max_lines = 4,
}

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require("cmp")

local function next_item(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  else
    fallback()
  end
end

local function prev_item(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  else
    fallback()
  end
end

cmp.setup({
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "vsnip" },
    { name = "path" },
  }),
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ["<S-Tab>"] = cmp.mapping(prev_item, { "i", "c", "s" }),

    ["<Tab>"] = cmp.mapping(next_item, { "i", "c", "s" }),

    ["<Enter>"] = cmp.mapping(
      cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
      }),
      { "i", "c", "s" }
    ),
  },
  window = {
    completion = {
      scrollbar = false,
    },
    documentation = cmp.config.disable,
  },
  experimental = {
    ghost_text = true,
  },
})
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "cmdline" }
  })
})

local telescope = require("telescope")
telescope.setup({
  defaults = {
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--follow",
    },
    winblend = vim.o.winblend,
    layout_config = {
      horizontal = {
        prompt_position = "bottom",
        width = 0.91,
        height = 0.975,
      },
    },
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {}
    },
  },
})
telescope.load_extension("ui-select")

-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#ccrust-via-lldb-vscode
local dap = require("dap")
dap.adapters.lldb = {
  type = "executable",
  command = "/usr/bin/env",
  args = { "lldb-vscode" },
  name = "lldb",
}
dap.configurations.rust = {
  {
    name = "Launch",
    type = "lldb",
    request = "launch",
    program = vim.fn.RustProjectExecutable(),
    cwd = "${workspaceFolder}",
    stopOnEntry = false,

    initCommands = function()
      -- Find out where to look for the pretty printer Python module
      local rustc_sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot"))

      local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
      local commands_file = rustc_sysroot .. "/lib/rustlib/etc/lldb_commands"

      local commands = {}
      local file = io.open(commands_file, "r")
      if file then
        for line in file:lines() do
          table.insert(commands, line)
        end
        file:close()
      end
      table.insert(commands, 1, script_import)

      return commands
    end,
  },
}

local dapui = require("dapui")
dapui.setup()

-- taken from https://github.com/rcarriga/nvim-dap-ui/
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end

EOF

" uncomment if debugging "interesting" behavior with spaces and the works
"colo default | exe '/\s'

" vim: sw=2 ts=2 et
