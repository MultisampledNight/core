colorscheme semi-duality

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
nnoremap <silent> P "+p
nnoremap <silent> Y "+y

vnoremap <silent> j gj
vnoremap <silent> k gk
vnoremap gn n<Cmd>noh<CR>
vnoremap gN N<Cmd>noh<CR>
vnoremap <silent> P "+p
vnoremap <silent> Y "+y

function TelescopeOnToplevel(command)
  silent update
  exe $'Telescope {a:command} cwd={g:toplevel}'
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

nnoremap <Leader><Leader> <Cmd>Telescope resume<CR>
nnoremap <Leader>f <Cmd>call TelescopeOnToplevel("find_files follow=true")<CR>
nnoremap <Leader>/ <Cmd>call TelescopeOnToplevel("live_grep")<CR> 
nnoremap gd <Cmd>call TelescopeOnToplevel("lsp_definitions")<CR>
nnoremap gu <Cmd>call TelescopeOnToplevel("lsp_references")<CR>
nnoremap <Leader>i <Cmd>call TelescopeOnToplevel("lsp_implementations")<CR>

nnoremap <Leader>o <Cmd>Trouble diagnostics toggle filter.severity = vim.diagnostic.severity.ERROR<CR>
nnoremap <Leader>x <Cmd>Trouble diagnostics toggle filter.severity.min = vim.diagnostic.severity.WARN<CR>
nnoremap <Leader>b <Cmd>update \| Trouble diagnostics<CR>

nnoremap <Leader>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
vnoremap <Leader>n <Cmd>update \| lua if require("dap").session() == nil then vim.lsp.buf.hover() else require("dap.ui.widgets").hover() end<CR>
nnoremap <Leader>r <Cmd>update \| lua vim.lsp.buf.rename()<CR>
nnoremap <Leader>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
vnoremap <Leader>a <Cmd>update \| lua vim.lsp.buf.code_action()<CR>
nnoremap <Leader>g <Cmd>call TelescopeOnToplevel("lsp_workspace_symbols")<CR>

nnoremap <Leader>s <Cmd>call TelescopeOnToplevel("treesitter")<CR>
nnoremap <Leader>w <Cmd>call TelescopeOnToplevel("keymaps")<CR>

nnoremap <Leader>. <Cmd>call TelescopeOnToplevel("git_status")<CR>
nnoremap <Leader>j <Cmd>call CreateNewFile()<CR>
nnoremap <Leader>c <Cmd>call RenameCurrentFile()<CR>
nnoremap <Leader>d <Cmd>call DeleteCurrentFile()<CR>

nnoremap <Esc> <Cmd>update<CR>
nnoremap <Leader>q <Cmd>update \| call jobstart("cargo fmt")<CR>

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
      au CursorHold,CursorHoldI * call UpdateIfPossible()
    endif

  augroup END
endfunction

function UpdateIfPossible()
  " this does not write if the file doesn't exist yet — this is intentional
  " to support deleting and renaming
  if &buftype == "" && filewritable(@%)
    silent update
  endif
endfunction

command AutoWriteToggle call AutoWriteToggle()
command AutoWrite call AutoWrite(v:true)
command AutoWriteDisable call AutoWrite(v:false)
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
lspconfig.typos_lsp.setup {}
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
}
lspconfig.nil_ls.setup {}
vim.lsp.set_log_level("error")

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
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<Leader><Enter>",
      scope_incremental = "<Leader>u",
      node_incremental = "<Leader>t",
      node_decremental = "<Leader>v",
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
  open_cmd = "webapp %s",
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
