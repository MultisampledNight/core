call plug#begin("~/.local/share/nvim/vim-plug")

Plug 'MultisampledNight/unsweetened'
Plug 'MultisampledNight/silentmission'
Plug 'MultisampledNight/samplednight'

Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'

Plug 'DingDean/wgsl.vim'
Plug 'ap/vim-css-color'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'sheerun/vim-polyglot'
Plug 'xuhdev/vim-latex-live-preview'

call plug#end()


" general settings
colorscheme unsweetened

set guifont=CamingoCode:h11
set termguicolors
set number
set noshowmode
set title
set titlestring=%m%h%w%F
set titlelen=0
set linebreak

set clipboard+=unnamedplus
set mouse=a
set completeopt=menuone,noselect
set ignorecase
set smartcase
set scrolloff=2
set sidescrolloff=6

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

vnoremap <S-k> <Cmd>lua require("dapui").eval()<CR>
nnoremap tb <Cmd>lua require("dap").toggle_breakpoint()<CR>
nnoremap tc <Cmd>lua require("dap").continue()<CR>
nnoremap tt <Cmd>lua require("dap").step_over()<CR>
nnoremap ti <Cmd>lua require("dap").step_into()<CR>
nnoremap tq <Cmd>lua require("dap").terminate()<CR>

nnoremap <F1> <NOP>
inoremap <F1> <NOP>

" neovide
hi! Normal guibg=#171c1c ctermfg=8 guifg=#b8b2b8
let g:neovide_refresh_rate = 60
let g:neovide_cursor_animation_length = 0.065
let g:neovide_cursor_vfx_mode = "pixiedust"
let g:neovide_cursor_vfx_particle_lifetime = 6.9
let g:neovide_cursor_vfx_particle_speed = 9
let g:neovide_cursor_vfx_particle_density = 18
let g:neovide_cursor_vfx_particle_opacity = 30.0

" rust
let g:rustfmt_autosave = 1

" latex live preview
let g:livepreview_previewer = "okular"
let g:livepreview_engine = "latexmk"

lua <<EOF
require("nvim-treesitter.configs").setup {
	highlight = {
		enable = true,
	},
}

local dap = require("dap")
local dapui = require("dapui")
dapui.setup({
	icons = { collapsed = "⮞", expanded = "⮟" },
	sidebar = {
		elements = {
			{ id = "breakpoints", size = 0.1 },
			{ id = "stacks", size = 0.25 },
			{ id = "watches", size = 0.1 },
			{ id = "scopes", size = 0.55 },
		},
		size = 42,
		tray = {
			size = 6,
		},
	}
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

dap.adapters.python = {
	type = "executable";
	command = "python";
	args = { "-m", "debugpy.adapter" };
}
dap.configurations.python = {
	{
		type = "python";
		request = "launch";
		name = "Launch file";

		program = "${file}";
		pythonPath = "/usr/bin/python";
	},
}

local extension_path = vim.fn.expand "~/info/lurk/codelldb/extension/"
local codelldb_path = extension_path .. "adapter/codelldb"
local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

dap.adapters.codelldb = function(callback, _)
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle
  local pid_or_err
  local port
  local error_message = ""

  local opts = {
    stdio = { nil, stdout, stderr },
    args = { "--liblldb", liblldb_path },
    detached = true,
  }

  handle, pid_or_err = vim.loop.spawn(codelldb_path, opts, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    if code ~= 0 then
      print("codelldb exited with code", code)
      print("error message", error_message)
    end
  end)

  assert(handle, "Error running codelldb: " .. tostring(pid_or_err))

  stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then
      if not port then
        local chunks = {}
        for substring in chunk:gmatch "%S+" do
          table.insert(chunks, substring)
        end
        port = tonumber(chunks[#chunks])
        vim.schedule(function()
          callback {
            type = "server",
            host = "127.0.0.1",
            port = port,
          }
        end)
      else
        vim.schedule(function()
          require("dap.repl").append(chunk)
        end)
      end
    end
  end)
  stderr:read_start(function(_, chunk)
    if chunk then
      error_message = error_message .. chunk

      vim.schedule(function()
        require("dap.repl").append(chunk)
      end)
    end
  end)
end

dap.configurations.rust = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
			local handle = io.popen("cargo exepath")
			local result = handle:read("*a")
			handle:close()
			return string.gsub(result, "[\n]+", "") 
		end,
		args = function()
			local args_iter = string.gmatch(vim.fn.input("launch args> ", "", "file"), "([^ ]+)")
			local args = {}

			for arg in args_iter do
				table.insert(args, arg)
			end

			return args
		end,
		cwd = "${workspaceFolder}",
  },
}
EOF

