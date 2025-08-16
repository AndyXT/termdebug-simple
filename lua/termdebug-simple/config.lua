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

---Validate configuration values
---@param config TermdebugSimpleConfig Configuration to validate
---@return boolean valid True if configuration is valid
---@return string|nil error Error message if invalid
local function validate_config(config)
	-- Validate debugger
	if type(config.debugger) ~= "string" or config.debugger == "" then
		return false, "debugger must be a non-empty string"
	end
	
	-- Validate keymap_prefix
	if type(config.keymap_prefix) ~= "string" then
		return false, "keymap_prefix must be a string"
	end
	
	-- Validate eclipse_keymaps
	if type(config.eclipse_keymaps) ~= "boolean" then
		return false, "eclipse_keymaps must be a boolean"
	end
	
	-- Validate uuid_marker
	if type(config.uuid_marker) ~= "string" or config.uuid_marker == "" then
		return false, "uuid_marker must be a non-empty string"
	end
	
	-- Validate popup configuration
	if type(config.popup) ~= "table" then
		return false, "popup must be a table"
	end
	
	local popup = config.popup
	
	-- Validate popup.width
	if type(popup.width) ~= "number" or popup.width <= 0 then
		return false, "popup.width must be a positive number"
	end
	
	-- Validate popup.height
	if type(popup.height) ~= "number" or popup.height <= 0 then
		return false, "popup.height must be a positive number"
	end
	
	-- Validate popup.relative
	local valid_relative = { "cursor", "win", "editor" }
	if not vim.tbl_contains(valid_relative, popup.relative) then
		return false, "popup.relative must be one of: " .. table.concat(valid_relative, ", ")
	end
	
	-- Validate popup.border
	local valid_borders = { "none", "single", "double", "rounded", "solid", "shadow" }
	if not vim.tbl_contains(valid_borders, popup.border) then
		return false, "popup.border must be one of: " .. table.concat(valid_borders, ", ")
	end
	
	-- Validate popup offset values
	if type(popup.row_offset) ~= "number" then
		return false, "popup.row_offset must be a number"
	end
	
	if type(popup.col_offset) ~= "number" then
		return false, "popup.col_offset must be a number"
	end
	
	-- Validate boolean options
	if type(popup.focusable) ~= "boolean" then
		return false, "popup.focusable must be a boolean"
	end
	
	if type(popup.scrollable) ~= "boolean" then
		return false, "popup.scrollable must be a boolean"
	end
	
	return true, nil
end

---Setup configuration with user options
---@param opts? TermdebugSimpleConfig User configuration options
---@return TermdebugSimpleConfig config Merged configuration
function M.setup(opts)
	opts = opts or {}
	local config = vim.tbl_deep_extend("force", defaults, opts)

	-- Validate the merged configuration
	local valid, error_msg = validate_config(config)
	if not valid then
		error("termdebug-simple configuration error: " .. error_msg)
	end

	if type(config.debugger_args) == "string" then
		config.debugger_args = vim.split(config.debugger_args, " ")
	end

	return config
end

return M
