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

return quiet
