colorscheme semi-duality

lua vim.fn.delete(vim.lsp.get_log_path())
runtime data.vim

" Silently (without cmdline feedback) writes the file if it has been modified.
command Upd call Upd()

function Upd()
  " this does not write if the file doesn't exist yet — this is intentional
  " to support deleting and renaming
  if &buftype == "" && filewritable(@%)
    nohlsearch
    silent update
  endif
endfunction

set winblend=10
set pumblend=10

set termguicolors
set guifont=JetBrainsMonoNL_NF_Light:h13
set linespace=4
set number
set noshowmode
set breakindent
set signcolumn=yes
set title
set titlestring=%m%h%w%F
set titlelen=0
set undofile
set shortmess+=W
set notimeout
set nottimeout
set linebreak
set nowrap

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

let g:date_format = g:data.date.short
let g:datetime_format = g:data.date.long


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
nnoremap gn n<Cmd>noh<Enter>
nnoremap gN N<Cmd>noh<Enter>
nnoremap <silent> P "+p
nnoremap <silent> Y "+y
nnoremap <silent> X "+X

vnoremap <silent> j gj
vnoremap <silent> k gk
vnoremap gn n<Cmd>noh<Enter>
vnoremap gN N<Cmd>noh<Enter>
vnoremap <silent> P "+p
vnoremap <silent> Y "+y
vnoremap <silent> X "+x

function TelescopeOnToplevel(command)
  Upd
  exe $'Telescope {a:command} cwd={g:toplevel}'
endfunction

" Opens the given file. If it doesn't already exist,
" also insert a template.
function OpenFile(path)
  exe "edit " . fnameescape(a:path)

  if filereadable(expand("%"))
    return
  endif

  write
  call InsertTemplate()
endfunction
function CreateNewFile()
  let sub_path = trim(input("New file name: ", expand("<cword>")))
  if sub_path == ""
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path

  call mkdir(fnamemodify(full_path, ":h"), "p")
  call OpenFile(full_path)
endfunction

" Populate the currently open file with an automatically found template.
" A template is any file named `_template` in any of the current or parent
" directories, ending with the extension also to be used by the current file.
" (Alternatively, a folder called _template with the extension as file name
" inside is also okay.)
"
" As an example, consider these files:
"
" ```
" /_template.typ
" /folder/_template.typ
" /folder/specific/_template.rs
" /folder/specific/new.typ
" ```
"
" When calling this function while `new.typ` is open,
" it will be filled with `/folder/_template.typ`.
" `/folder/specific/_template.rs` is nearer, but ends in `.rs`, not `.typ`,
" and `/_template.typ` is a directory too far (the path components are
" traversed from end to start in the search process).
function InsertTemplate()
  let template = FindTemplate()
  if template == v:null
    " no template there to put in qwq
    return
  endif

  " minus so it's done at the current line, not below it
  exe "-read " . fnameescape(template)
  call RealizeVariables()
  Upd
endfunction

function FindTemplate()
  " traverse directories from end of path to start of path,
  " looking for _template.ext or _template/ext in each
  let prefix = "_template"
  let ext = expand("%:e")

  " note: currently points at the file, too: will be removed in the 1st iter
  let looking_under = expand("%:p")
  
  while looking_under != "/"
    " go one path component up
    let looking_under = fnamemodify(looking_under, ":h")

    " anything like it?
    let separators = [".", "/"]
    for sep in separators
      let template = prefix . sep . ext
      let candidate = looking_under . "/" . template

      if filereadable(candidate)
        " yeah, that's it! yay!
        return candidate
      endif
    endfor
  endwhile

  return v:null
endfunction

function RealizeVariables()
  " substitute cfg values
  " e.g. %now% -> 2025-06-10 15:36:55
  let vars = #{
    \ title: expand("%:t:r"),
    \ now: strftime(g:datetime_format),
  \ }

  let [start, end] = ["%", "%"]
  for [name, value] in items(vars)
    exe 'sil! %s/' . start . name . end . '/' . value . '/Ieg'
  endfor

  noh

  " position the cursor
  " if it's %cursor.insert%, do switch into insert mode as well
  let regex = start . 'cursor\(\.\(normal\|insert\)\|\)' . end
  let matches = matchbufline(bufnr("%"), regex, 1, "$", #{submatches: v:true})
  if empty(matches)
    norm G
    return
  endif

  let line = matches[0].lnum
  let kind = matches[0].submatches[1]
  exe 'norm /' . regex . "\<Enter>\"_d//e\<Enter>"

  if kind == 'insert'
    startinsert
  endif

  noh
endfunction

function RenameCurrentFile()
  let old = expand("%:t")
  let sub_path = trim(input("Rename to: ", old))
  if sub_path == ""
    return
  elseif sub_path ==# old
    echo "Already named that way"
    return
  endif

  let full_path = expand("%:.:h") . "/" . sub_path
  call mkdir(fnamemodify(full_path, ":h"), "p")
  exe "saveas " . full_path

  call delete(@#)
endfunction

function DeleteCurrentFile()
  if trim(input("Are you sure? ")) !~ 'y\|yes'
    return
  endif

  if delete(@%)
    return
  endif

  quit
endfunction

" Opens a terminal emulator in an external window.
function Terminal(cwd = ".")
  let cmd = ["alacritty"]
  let opts = #{detach: v:true, stdin: "null", cwd: a:cwd}
  call jobstart(cmd, opts)
endfunction

" Toggles a pane showing all document symbols
" as provided by the LSP server.
function ToggleSymbols()
lua <<EOF
  require("trouble").toggle({
    mode = "symbols",
    filter = {
      buf = 0,
    },
    win = {
      position = "right",
      wo = {
        -- otherwise the heading name is shown twice
        winhighlight = "Comment:Hide",
      },
    }
  })
EOF
endfunction

nnoremap <Leader><Leader> <Cmd>Telescope resume<Enter>
nnoremap <Leader>f <Cmd>call TelescopeOnToplevel("find_files follow=true")<Enter>
nnoremap <Leader>/ <Cmd>call TelescopeOnToplevel("live_grep")<Enter> 
nnoremap gd <Cmd>call TelescopeOnToplevel("lsp_definitions")<Enter>
nnoremap gu <Cmd>call TelescopeOnToplevel("lsp_references")<Enter>
nnoremap <Leader>i <Cmd>call TelescopeOnToplevel("lsp_implementations")<Enter>

nmap <X1Mouse> <LeftMouse>gd
nmap <X2Mouse> <LeftMouse><C-o>

" open a terminal in the project root
noremap <Leader>x <Cmd>call Terminal()<Enter>
" open a terminal in the current file's folder
noremap <Leader>e <Cmd>call Terminal(expand("%:p:h"))<Enter>

nnoremap <Leader>o <Cmd>Trouble diagnostics toggle focus=false filter.severity=vim.diagnostic.severity.ERROR<Enter>
nnoremap <Leader>b <Cmd>update \| Trouble diagnostics<Enter>
nnoremap <Leader>v <Cmd>call ToggleSymbols()<Enter>

nnoremap <Leader>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<Enter>
vnoremap <Leader>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<Enter>
nnoremap <Leader>r <Cmd>update \| lua vim.lsp.buf.rename()<Enter>
nnoremap <Leader>a <Cmd>update \| lua vim.lsp.buf.code_action()<Enter>
vnoremap <Leader>a <Cmd>update \| lua vim.lsp.buf.code_action()<Enter>
nnoremap <Leader>g <Cmd>call TelescopeOnToplevel("lsp_workspace_symbols")<Enter>

nnoremap <Leader>s <Cmd>call TelescopeOnToplevel("treesitter")<Enter>
nnoremap <Leader>w <Cmd>call TelescopeOnToplevel("keymaps")<Enter>

nnoremap <Leader>. <Cmd>call TelescopeOnToplevel("git_status")<Enter>
nnoremap <Leader>j <Cmd>call CreateNewFile()<Enter>
nnoremap <Leader>c <Cmd>call RenameCurrentFile()<Enter>
nnoremap <Leader>d <Cmd>call DeleteCurrentFile()<Enter>

" InsertTemplate is also called automatically.
" some systems allow nested logical files within a physical file though,
" so the user may wish to add the template one more time
nnoremap <Leader>, <Cmd>call InsertTemplate()<Enter>

nnoremap <Esc> <Cmd>Upd<Enter>
nnoremap <Leader>q <Cmd>eval [Upd(), b:format()]<Enter>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
let g:neovide_refresh_rate = 60
let g:neovide_refresh_rate_idle = 5
let g:neovide_cursor_unfocused_outline_width = 0.1
let g:neovide_cursor_animation_length = 0.25
let g:neovide_cursor_short_animation_length = 0.125
let g:neovide_position_animation_length = 0.25
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
runtime lang/mod.vim

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
      au CursorHold,CursorHoldI * Upd
    endif

  augroup END
endfunction

command AutoWriteToggle call AutoWriteToggle()
command AutoWrite call AutoWrite(v:true)
command AutoWriteDisable call AutoWrite(v:false)
command RVar call RealizeVariables()
autocmd FocusGained * checktime


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
lspconfig.ts_ls.setup {}
lspconfig.typos_lsp.setup {
  init_options = {
    config = vim.env.core .. "/config/typos/config.toml",
  },
}
lspconfig.tinymist.setup {
  settings = {
    formatterPrintWidth = 80,
    completion = {
      postfix = true,
    },

    rootPath = vim.g.toplevel,
    exportPdf = "onSave",
    outputPath = "$root/target/view.pdf",
  },
  offset_encoding = "utf-8",
}
lspconfig.nil_ls.setup {}
lspconfig.jdtls.setup {}
lspconfig.julials.setup {}
vim.lsp.set_log_level("error")

require("trouble").setup({
  open_no_results = true,
  focus = true,
  multiline = false,
  win = {
    position = "bottom",
    height = 9,
  },
  icons = {
    folder_closed = "-",
    folder_open = ":",
    kinds = {
      Array = "array",
      Boolean = "bool",
      Class = "cls",
      Constant = "const",
      Constructor = "constr",
      Enum = "enum",
      EnumMember = "variant",
      Event = "ev",
      Field = "field",
      File = "file",
      Function = "fn",
      Method = "fn",
      Interface = "if",
      Module = "mod",
      Namespace = "=",
      Null = "null",
      Number = "num",
      Object = "obj",
      Operator = "op",
      Package = "pkg",
      Property = "prop",
      String = "str",
      Struct = "struct",
      TypeParameter = "generic",
      Variable = "var",
    },
  },
})

require("nvim-treesitter.configs").setup {
  highlight = {
    enable = true,
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<Leader><Enter>",
      scope_incremental = "<Leader>u",
      node_incremental = "<Leader>t",
    },
  },
}

require("treesitter-context").setup {
  max_lines = 4,
}
require("nvim-ts-autotag").setup {}
require("rainbow-delimiters.setup").setup {
  highlight = vim.g.rainbow_hl,
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

local bin = "/run/current-system/sw/bin"

require("typst-preview").setup {
  open_cmd = "webapp %s 2>/dev/null",
  dependencies_bin = {
    ["tinymist"] = bin .. "/tinymist",
    ["websocat"] = bin .. "/websocat",
  },
  get_root = function(_)
    return vim.g.toplevel
  end,

  invert_colors = "never",
  extra_args = {
    "--input=dev=true",
  },
}

EOF

" uncomment if debugging "interesting" behavior with spaces and the works
"colo default | exe '/\s'

" vim: sw=2 ts=2 et
