---@class TermdebugSimpleConfig
---@field debugger string GDB executable path
---@field debugger_args string|string[] Arguments to pass to debugger
---@field keymap_prefix string Prefix for non-Eclipse keymaps
---@field eclipse_keymaps boolean Enable Eclipse-style F-key mappings
---@field popup TermdebugSimplePopupConfig Popup window configuration
---@field uuid_marker string UUID marker prefix for output parsing

---@class TermdebugSimplePopupConfig
---@field border string Border style ("none", "single", "double", "rounded", "solid", "shadow")
---@field width integer Popup window width
---@field height integer Maximum popup window height
---@field relative string Position relative to ("cursor", "win", "editor")
---@field row_offset integer Row offset from anchor
---@field col_offset integer Column offset from anchor
---@field focusable boolean Allow focusing the popup window
---@field scrollable boolean Enable scrolling in popup

local M = {}

---@type TermdebugSimpleConfig
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

---Setup configuration with user options
---@param opts? TermdebugSimpleConfig User configuration options
---@return TermdebugSimpleConfig config Merged configuration
function M.setup(opts)
	opts = opts or {}
	local config = vim.tbl_deep_extend("force", defaults, opts)

	if type(config.debugger_args) == "string" then
		config.debugger_args = vim.split(config.debugger_args, " ")
	end

	return config
end

return M
