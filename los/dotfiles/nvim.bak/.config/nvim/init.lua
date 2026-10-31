vim.opt.termguicolors = true

-- vim.pack.add({
-- 	{
-- 		src = "https://github.com/rose-pine/neovim",
-- 		name = "rose-pine",
-- 	},
-- })
--
-- require("rose-pine").setup({
-- 	variant = "main",
--
-- 	palette = {
-- 		main = {
-- 			base = "#000000",
-- 			surface = "#000000",
-- 			overlay = "#000000",
-- 		},
-- 	},
--
-- 	highlight_groups = {
-- 		Normal = { bg = "#000000" },
-- 		NormalNC = { bg = "#000000" },
-- 		NormalFloat = { bg = "#000000" },
-- 		FloatBorder = { bg = "#000000" },
-- 		SignColumn = { bg = "#000000" },
-- 		LineNr = { bg = "#000000" },
-- 		CursorLine = { bg = "#000000" },
-- 		StatusLine = { bg = "#000000" },
-- 		Pmenu = { bg = "#000000" },
-- 		EndOfBuffer = { bg = "#000000" },
-- 	},
-- })
--
-- vim.cmd.colorscheme("rose-pine")

-- +---+---+ +---+---+ +---+---+
-- + core/ui.lua
-- +---+---+ +---+---+ +---+---+
-- vim.cmd("highlight SignColumn guibg=#000000")
-- vim.pack.add({
-- 	{ src = "https://github.com/morhetz/gruvbox" },
-- })
--
-- -- Fix colored backgrounds on syntax highlights
-- vim.g.gruvbox_guisp_fallback = "NONE"
-- vim.g.gruvbox_inverse = 0
--
-- -- Load default Gruvbox
-- vim.cmd.colorscheme("gruvbox")
--
-- -- Pure black background only
-- vim.cmd("highlight Normal guibg=#000000")
-- vim.cmd("highlight NormalNC guibg=#000000")
-- vim.cmd("highlight EndOfBuffer guibg=#000000")

-- vim.pack.add({
-- 	"https://github.com/rebelot/kanagawa.nvim",
-- })
-- vim.cmd.colorscheme("kanagawa-dragon")
--
-- vim.api.nvim_set_hl(0, "Cursor", {
-- 	bg = "#C4B28A",
-- 	fg = "#181616",
-- })

-- vim.pack.add({
-- 	{ src = "https://github.com/WTFox/luna.nvim" },
-- })
-- vim.cmd.colorscheme("luna")

-- vim.pack.add({
-- 	"https://github.com/shaunsingh/nord.nvim",
-- })
--
-- vim.cmd.colorscheme("nord")
--
-- vim.g.nord_contrast = true
-- vim.g.nord_borders = true
-- vim.g.nord_disable_background = true
-- vim.g.nord_italic = false
-- vim.g.nord_bold = false
--
-- require("nord").set()

-- vim.pack.add({ "https://github.com/drewxs/ash.nvim" })
-- vim.cmd([[colorscheme ash]])
--
-- vim.cmd([[
--   highlight Normal guibg=NONE ctermbg=NONE
--   highlight NormalNC guibg=NONE ctermbg=NONE
--   highlight NonText guibg=NONE ctermbg=NONE
--   highlight SignColumn guibg=NONE ctermbg=NONE
--   highlight EndOfBuffer guibg=NONE ctermbg=NONE
--   highlight LineNr guibg=NONE ctermbg=NONE
--   highlight Folded guibg=NONE ctermbg=NONE
--   highlight VertSplit guibg=NONE ctermbg=NONE
-- ]])

-- Nice ones to switch around between
-- vim.pack.add({ "https://github.com/xLeapProtocol/ring0-dark.nvim" })
-- vim.cmd.colorscheme("ring0dark")
-- vim.cmd.colorscheme("lunaperche")
-- vim.cmd.colorscheme("habamax")
-- vim.cmd.colorscheme("koehler")
-- vim.cmd.colorscheme("industry")
-- vim.cmd.colorscheme("pablo")
-- vim.cmd.colorscheme("murphy")
-- vim.cmd.colorscheme("zaibatsu")

-- +---+---+ +---+---+ +---+---+
-- + core/options.lua
-- +---+---+ +---+---+ +---+---+

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = false
vim.opt.wrap = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.background = "dark"

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.signcolumn = "no"
vim.opt.colorcolumn = "0"
vim.opt.showmatch = true
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false
vim.opt.laststatus = 2
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0
vim.opt.conceallevel = 2
vim.opt.concealcursor = ""
vim.opt.synmaxcol = 300
vim.opt.fillchars = { eob = " " }

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
-- vim.opt.undofile = true
-- vim.opt.undodir = undodir
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.autoread = true
vim.opt.autowrite = false

vim.opt.hidden = true
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.autochdir = false
vim.opt.iskeyword:append("-")
vim.opt.path:append("**")
vim.opt.selection = "inclusive"
vim.opt.mouse = "a"
vim.opt.clipboard:append("unnamedplus")
vim.opt.modifiable = true

-- vim.opt.guicursor =
-- 	"n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

vim.opt.guicursor = "a:block-blinkon0"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.diffopt:append("linematch:60")
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000

-- +---+---+ +---+---+ +---+---+
-- + core/keymaps.lua
-- +---+---+ +---+---+ +---+---+

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })

vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "<leader>e", "<cmd>Oil<cr>")
vim.keymap.set("n", "<leader>pm", "<cmd>Mason<cr>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "D", "C")
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<leader><leader>", function()
	require("telescope.builtin").find_files()
end)

vim.keymap.set("n", "<leader>fg", function()
	require("telescope.builtin").live_grep()
end)

vim.keymap.set("n", "<leader>b", function()
	require("telescope.builtin").buffers()
end)

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- +---+---+ +---+---+ +---+---+
-- + core/quiet.lua
-- +---+---+ +---+---+ +---+---+

local quiet = {
	enabled = true,
	servers = {},
}

local function hide_suggestions()
	local ok, cmp = pcall(require, "blink.cmp")
	if not ok then
		return
	end

	cmp.hide()
	cmp.hide_documentation()
	cmp.hide_signature()
end

function quiet.is_enabled()
	return quiet.enabled
end

function quiet.setup(servers)
	quiet.servers = servers

	vim.api.nvim_create_user_command("Quiet", function()
		if not quiet.enabled then
			vim.notify("Quiet mode is already on")
			return
		end

		quiet.enabled = false
		hide_suggestions()
		vim.lsp.enable(quiet.servers, false)
		vim.notify("Quiet mode on: LSPs and suggestions disabled")
	end, { desc = "Disable all LSPs and completion suggestions" })

	vim.api.nvim_create_user_command("QuietOff", function()
		if quiet.enabled then
			vim.notify("Quiet mode is already off")
			return
		end

		quiet.enabled = true
		vim.lsp.enable(quiet.servers)
		vim.notify("Quiet mode off: LSPs and suggestions enabled")
	end, { desc = "Re-enable all LSPs and completion suggestions" })
end

-- +---+---+ +---+---+ +---+---+
-- + core/statusline.lua
-- +---+---+ +---+---+ +---+---+

-- local statusline = {}
--
-- local function highlights()
-- 	vim.api.nvim_set_hl(0, "RetroStatus", {
-- 		fg = "#bcbcbc",
-- 		bg = "#1c1c1c",
-- 		ctermfg = 250,
-- 		ctermbg = 234,
-- 	})
--
-- 	vim.api.nvim_set_hl(0, "RetroMode", {
-- 		fg = "#1c1c1c",
-- 		bg = "#d0d0d0",
-- 		bold = true,
-- 		ctermfg = 234,
-- 		ctermbg = 252,
-- 	})
--
-- 	vim.api.nvim_set_hl(0, "RetroMuted", {
-- 		fg = "#949494",
-- 		bg = "#1c1c1c",
-- 		ctermfg = 246,
-- 		ctermbg = 234,
-- 	})
-- end
--
-- local modes = {
-- 	n = "NORMAL",
-- 	i = "INSERT",
-- 	v = "VISUAL",
-- 	V = "V-LINE",
-- 	["\22"] = "V-BLOCK",
-- 	s = "SELECT",
-- 	S = "S-LINE",
-- 	["\19"] = "S-BLOCK",
-- 	R = "REPLACE",
-- 	c = "COMMAND",
-- 	r = "PROMPT",
-- 	["!"] = "SHELL",
-- 	t = "TERM",
-- }
--
-- function statusline.render()
-- 	local mode = vim.api.nvim_get_mode().mode
-- 	local label = modes[mode:sub(1, 1)] or "NORMAL"
--
-- 	if mode:sub(1, 2) == "no" then
-- 		label = "OPERATOR"
-- 	end
--
-- 	local width = vim.o.columns
--
-- 	local parts = {
-- 		"%#RetroMode# " .. label .. " ",
-- 		"%#RetroStatus# %<%f %m%r",
-- 		"%=",
-- 		"%#RetroMuted#",
-- 	}
--
-- 	if width >= 80 then
-- 		table.insert(parts, " %{&filetype == '' ? '-' : &filetype} |")
-- 	end
--
-- 	table.insert(parts, " %l:%c ")
--
-- 	if width >= 60 then
-- 		table.insert(parts, "| %p%% ")
-- 	end
--
-- 	if width >= 100 then
-- 		table.insert(parts, "| %{strftime('%H:%M')} ")
-- 	end
--
-- 	return table.concat(parts)
-- end
--
-- vim.opt.laststatus = 3
-- vim.opt.showmode = false
--
-- -- Expose only the render function Neovim needs for statusline evaluation.
-- _G.zen_statusline_render = statusline.render
--
-- vim.opt.statusline = "%!v:lua.zen_statusline_render()"
--
-- local statusline_group = vim.api.nvim_create_augroup("RetroStatusline", { clear = true })
--
-- vim.api.nvim_create_autocmd("ColorScheme", {
-- 	group = statusline_group,
-- 	callback = highlights,
-- })
--
-- vim.api.nvim_create_autocmd("ModeChanged", {
-- 	group = statusline_group,
-- 	callback = function()
-- 		vim.cmd.redrawstatus()
-- 	end,
-- })
--
-- highlights()
--
-- local statusline_timer = vim.fn.timer_start(30000, function()
-- 	vim.cmd.redrawstatus()
-- end, { ["repeat"] = -1 })
--
-- vim.api.nvim_create_autocmd("VimLeavePre", {
-- 	group = statusline_group,
-- 	callback = function()
-- 		if statusline_timer ~= -1 then
-- 			vim.fn.timer_stop(statusline_timer)
-- 		end
-- 	end,
-- })

-- +---+---+ +---+---+ +---+---+
-- + plugins/init.lua
-- +---+---+ +---+---+ +---+---+

local specs = {
	{ src = "https://github.com/WTFox/luna.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/folke/snacks.nvim" },
	{
		src = "https://github.com/Saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	{ src = "https://github.com/windwp/nvim-autopairs" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/windwp/nvim-ts-autotag" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
}

vim.pack.add(specs, { confirm = false, load = true })

-- +---+---+ +---+---+ +---+---+
-- + plugins/editor.lua
-- +---+---+ +---+---+ +---+---+

require("telescope").setup({})

require("oil").setup({
	default_file_explorer = true,
	columns = {},
	view_options = {
		show_hidden = true,
	},
})

require("nvim-autopairs").setup({})

require("gitsigns").setup({
	signs = {
		add = { text = "│" },
		change = { text = "│" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
		untracked = { text = "┆" },
	},
	signs_staged = {
		add = { text = "┃" },
		change = { text = "┃" },
		delete = { text = "━" },
		topdelete = { text = "━" },
		changedelete = { text = "┫" },
		untracked = { text = "┋" },
	},
	signs_staged_enable = true,
	signcolumn = true,
	numhl = false,
	linehl = false,
	current_line_blame = false,
})

-- +---+---+ +---+---+ +---+---+
-- + plugins/completion.lua
-- +---+---+ +---+---+ +---+---+

local function inside_leptos_view()
	local ok, node = pcall(vim.treesitter.get_node)

	if not ok then
		return false
	end

	while node do
		if node:type() == "delim_nodes" then
			return true
		end

		node = node:parent()
	end

	return false
end

local function drop_stray_emmet(_, items)
	if vim.bo.filetype ~= "rust" or inside_leptos_view() then
		return items
	end

	return vim.tbl_filter(function(item)
		local client = vim.lsp.get_client_by_id(item.client_id)
		return not client or client.name ~= "emmet_language_server"
	end, items)
end

require("blink.cmp").setup({
	enabled = function()
		return quiet.is_enabled()
	end,
	keymap = {
		preset = "none",
		["<C-Space>"] = {
			"show",
			"show_documentation",
			"hide_documentation",
		},
		["<C-n>"] = { "select_next", "fallback" },
		["<C-p>"] = { "select_prev", "fallback" },
		["<Tab>"] = { "accept", "fallback" },
		["<C-y>"] = { "accept", "fallback" },
		["<C-e>"] = { "hide", "fallback" },
	},
	completion = {
		documentation = {
			auto_show = false,
		},
	},
	sources = {
		default = {
			"lsp",
			"path",
			"snippets",
			"buffer",
		},
		providers = {
			lsp = {
				transform_items = drop_stray_emmet,
			},
		},
	},
	fuzzy = {
		implementation = "prefer_rust_with_warning",
	},
	cmdline = {
		enabled = false,
	},
	term = {
		enabled = false,
	},
})

-- +---+---+ +---+---+ +---+---+
-- + plugins/treesitter.lua
-- +---+---+ +---+---+ +---+---+

local parsers = {
	"lua",
	"vim",
	"vimdoc",
	"query",
	"python",
	"javascript",
	"typescript",
	"tsx",
	"html",
	"css",
	"json",
	"rust",
	"rust_with_rstml",
}

local rstml = {
	install_info = {
		url = "https://github.com/rayliwell/tree-sitter-rstml",
		revision = "2d4c2bc84a40d99a4e099ff7c6cf7f1bc5dc7806",
		location = "rust_with_rstml",
		queries = "queries/rust_with_rstml",
	},
	tier = 2,
}

vim.api.nvim_create_autocmd("User", {
	pattern = "TSUpdate",
	group = vim.api.nvim_create_augroup("z_treesitter", { clear = true }),
	callback = function()
		require("nvim-treesitter.parsers").rust_with_rstml = rstml
	end,
})

require("nvim-treesitter.parsers").rust_with_rstml = rstml

require("nvim-treesitter").install(parsers)

if pcall(vim.treesitter.language.add, "rust_with_rstml") then
	vim.treesitter.language.register("rust_with_rstml", "rust")
end

vim.treesitter.language.register("json", "jsonc")
vim.treesitter.language.register("javascript", "javascriptreact")
vim.treesitter.language.register("tsx", "typescriptreact")

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"lua",
		"vim",
		"help",
		"query",
		"python",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"html",
		"css",
		"scss",
		"json",
		"jsonc",
		"rust",
	},
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})

-- +---+---+ +---+---+ +---+---+
-- + plugins/lsp.lua
-- +---+---+ +---+---+ +---+---+

require("mason").setup({})

local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
	capabilities = capabilities,
})

vim.lsp.config("pyright", {
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "basic",
			},
		},
	},
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				checkThirdParty = false,
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})

local function with_rust(server)
	local filetypes = vim.deepcopy(vim.lsp.config[server].filetypes or {})

	table.insert(filetypes, "rust")

	return filetypes
end

local tailwind_root_dir = vim.lsp.config.tailwindcss.root_dir

vim.lsp.config("tailwindcss", {
	filetypes = with_rust("tailwindcss"),

	root_dir = function(bufnr, on_dir)
		if vim.bo[bufnr].filetype ~= "rust" then
			return tailwind_root_dir(bufnr, on_dir)
		end

		tailwind_root_dir(bufnr, function(dir)
			if dir then
				return on_dir(dir)
			end

			local manifests = vim.fs.find("Cargo.toml", {
				path = vim.api.nvim_buf_get_name(bufnr),
				upward = true,
				limit = math.huge,
			})

			on_dir(vim.fs.dirname(manifests[#manifests]))
		end)
	end,

	settings = {
		tailwindCSS = {
			includeLanguages = {
				rust = "html",
			},
			experimental = {
				classRegex = {
					'class[:=]\\s*"([^"]*)"',
					'class[:=]\\s*move\\s*\\|\\|\\s*{?\\s*"([^"]*)"',
				},
			},
		},
	},
})

vim.lsp.config("emmet_language_server", {
	filetypes = with_rust("emmet_language_server"),
	root_markers = {
		".git",
		"Cargo.toml",
		"package.json",
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("z_lsp", { clear = true }),

	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client and client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end

		if client and client.name == "rust_analyzer" then
			local filename = vim.api.nvim_buf_get_name(args.buf)

			local project = vim.fs.root(filename, {
				"Cargo.toml",
				"rust-project.json",
			})

			if filename ~= "" and not project then
				client.settings = client.settings or {}

				client.settings["rust-analyzer"] = client.settings["rust-analyzer"] or {}

				local linked = client.settings["rust-analyzer"].linkedProjects or {}

				if not vim.tbl_contains(linked, filename) then
					table.insert(linked, filename)

					client.settings["rust-analyzer"].linkedProjects = linked

					client:notify("workspace/didChangeConfiguration", { settings = client.settings })
				end
			end
		end
	end,
})

local servers = {
	"pyright",
	"ruff",
	"ts_ls",
	"eslint",
	"emmet_language_server",
	"html",
	"cssls",
	"tailwindcss",
	"jsonls",
	"rust_analyzer",
	"lua_ls",
}

require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_enable = servers,
})

quiet.setup(servers)

require("mason-tool-installer").setup({
	ensure_installed = {
		"pyright",
		"ruff",
		"typescript-language-server",
		"eslint-lsp",
		"emmet-language-server",
		"html-lsp",
		"css-lsp",
		"tailwindcss-language-server",
		"json-lsp",
		"rust-analyzer",
		"lua-language-server",
		"prettier",
		"stylua",
	},
	auto_update = false,
	run_on_start = true,
	start_delay = 0,
	integrations = {
		["mason-lspconfig"] = true,
		["mason-null-ls"] = false,
		["mason-nvim-dap"] = false,
	},
})

-- +---+---+ +---+---+ +---+---+
-- + plugins/format.lua
-- +---+---+ +---+---+ +---+---+

local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		python = {
			"ruff_fix",
			"ruff_organize_imports",
			"ruff_format",
		},
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		scss = { "prettier" },
		less = { "prettier" },
		json = { "prettier" },
		jsonc = { "prettier" },
		rust = {
			"rustfmt",
			"leptosfmt",
		},
		lua = { "stylua" },
	},
	format_on_save = {
		timeout_ms = 3000,
		lsp_format = "never",
	},
	notify_on_error = true,
	notify_no_formatters = false,
})

vim.api.nvim_create_user_command("Format", function(args)
	conform.format({
		async = args.bang,
		timeout_ms = 3000,
		lsp_format = "never",
	})
end, {
	bang = true,
	desc = "Format the current buffer",
})
