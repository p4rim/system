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
