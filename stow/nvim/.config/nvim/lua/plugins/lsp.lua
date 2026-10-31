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

			on_dir(manifests[#manifests] and vim.fs.dirname(manifests[#manifests]) or nil)
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

require("core.quiet").setup(servers)

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
