vim.opt.termguicolors = true

vim.pack.add({
	{
		src = "https://github.com/rose-pine/neovim",
		name = "rose-pine",
	},
})

require("rose-pine").setup({
	variant = "main",

	styles = {
		transparency = true,
	},

	palette = {
		main = {
			base = "#000000",
			surface = "#000000",
			overlay = "#000000",
		},
	},

	highlight_groups = {
		ColorColumn = { bg = "#262626" },
		Normal = { bg = "NONE" },
		NormalNC = { bg = "NONE" },
		NormalFloat = { bg = "NONE" },
		FloatBorder = { bg = "NONE" },
		SignColumn = { bg = "NONE" },
		LineNr = { bg = "NONE" },
		CursorLine = { bg = "NONE" },
		StatusLine = { bg = "NONE" },
		Pmenu = { bg = "NONE" },
		EndOfBuffer = { bg = "NONE" },
	},
})

vim.cmd.colorscheme("rose-pine")
