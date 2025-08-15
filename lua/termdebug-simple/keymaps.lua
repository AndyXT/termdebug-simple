local M = {}
local commands = nil

function M.setup(config)
	commands = require("termdebug-simple.commands")

	if config.eclipse_keymaps then
		vim.keymap.set("n", "<F5>", commands.step_into, { desc = "Debug: Step Into" })
		vim.keymap.set("n", "<F6>", commands.step_over, { desc = "Debug: Step Over" })
		vim.keymap.set("n", "<F7>", commands.step_out, { desc = "Debug: Step Out" })
		vim.keymap.set("n", "<F8>", commands.continue, { desc = "Debug: Continue" })
		vim.keymap.set("n", "<F9>", commands.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<S-F5>", commands.stop, { desc = "Debug: Stop" })
	end

	local prefix = config.keymap_prefix
	vim.keymap.set("n", prefix .. "K", commands.evaluate_expression, { desc = "Debug: Evaluate Variable" })
	vim.keymap.set("n", prefix .. "b", commands.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
	vim.keymap.set("n", prefix .. "r", commands.run_to_cursor, { desc = "Debug: Run to Cursor" })
	vim.keymap.set("n", prefix .. "l", commands.list_breakpoints, { desc = "Debug: List Breakpoints" })
	vim.keymap.set("n", prefix .. "s", function()
		commands.start_debug_session()
	end, { desc = "Debug: Start Session" })

	vim.keymap.set("n", prefix .. "i", commands.step_into, { desc = "Debug: Step Into" })
	vim.keymap.set("n", prefix .. "o", commands.step_over, { desc = "Debug: Step Over" })
	vim.keymap.set("n", prefix .. "u", commands.step_out, { desc = "Debug: Step Out" })
	vim.keymap.set("n", prefix .. "c", commands.continue, { desc = "Debug: Continue" })
	vim.keymap.set("n", prefix .. "q", commands.stop, { desc = "Debug: Stop/Quit" })
end

return M

