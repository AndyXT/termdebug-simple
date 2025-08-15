local M = {}

local defaults = {
	debugger = "gdb",
	debugger_args = "-x .gdbinit",
	keymap_prefix = "<leader>m",
	eclipse_keymaps = true,
	popup = {
		border = "rounded",
		width = 60,
		height = 10,
		relative = "cursor",
		row_offset = 1,
		col_offset = 0,
		focusable = true,
		scrollable = true,
	},
	uuid_marker = "TERMDEBUG_SIMPLE_UUID_",
}

function M.setup(opts)
	opts = opts or {}
	local config = vim.tbl_deep_extend("force", defaults, opts)

	if type(config.debugger_args) == "string" then
		config.debugger_args = vim.split(config.debugger_args, " ")
	end

	return config
end

return M

