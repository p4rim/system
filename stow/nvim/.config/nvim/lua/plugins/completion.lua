local quiet = require("core.quiet")

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
