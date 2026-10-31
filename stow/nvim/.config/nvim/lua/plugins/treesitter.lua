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
