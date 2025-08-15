---@class TermdebugSimplePopup
local M = {}
local api = vim.api

---@class PopupState
---@field buf integer|nil Buffer number
---@field win integer|nil Window ID
local current_popup = {
	buf = nil,
	win = nil,
}

---Close the current popup window
local function close_popup()
	if current_popup.win and api.nvim_win_is_valid(current_popup.win) then
		api.nvim_win_close(current_popup.win, true)
	end
	if current_popup.buf and api.nvim_buf_is_valid(current_popup.buf) then
		api.nvim_buf_delete(current_popup.buf, { force = true })
	end
	current_popup.buf = nil
	current_popup.win = nil
end

---Show content in a popup window
---@param content string|string[] Content to display (string or array of lines)
---@param opts? table Optional configuration overrides
---@return PopupState popup Current popup state
function M.show(content, opts)
	opts = opts or {}
	local config = require("termdebug-simple.config").setup({})

	close_popup()

	local lines = {}
	if type(content) == "string" then
		lines = vim.split(content, "\n")
	else
		lines = content
	end

	local width = opts.width or config.popup.width
	local height = math.min(#lines + 2, opts.height or config.popup.height)

	for i, line in ipairs(lines) do
		if line and #line > width - 2 then
			lines[i] = string.sub(line, 1, width - 5) .. "..."
		end
	end

	current_popup.buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(current_popup.buf, 0, -1, false, lines)
	vim.bo[current_popup.buf].modifiable = false
	vim.bo[current_popup.buf].buftype = "nofile"

	local win_opts = {
		relative = config.popup.relative,
		width = width,
		height = height,
		row = config.popup.row_offset,
		col = config.popup.col_offset,
		style = "minimal",
		border = config.popup.border,
		focusable = config.popup.focusable,
	}

	if opts.title then
		win_opts.title = opts.title
		win_opts.title_pos = "center"
	end

	current_popup.win = api.nvim_open_win(current_popup.buf, false, win_opts)

	if config.popup.focusable then
		api.nvim_set_current_win(current_popup.win)
	end

	local close_keys = { "q", "<Esc>" }
	for _, key in ipairs(close_keys) do
		api.nvim_buf_set_keymap(current_popup.buf, "n", key, "", {
			callback = close_popup,
			noremap = true,
			silent = true,
			desc = "Close popup",
		})
	end

	if config.popup.scrollable then
		vim.wo[current_popup.win].wrap = false
		vim.wo[current_popup.win].scrolloff = 0
	end

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
		buffer = vim.api.nvim_get_current_buf(),
		once = true,
		callback = function()
			if not opts.persistent then
				close_popup()
			end
		end,
	})

	return current_popup
end

---Close the current popup window
function M.close()
	close_popup()
end

return M
