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

---Calculate smart popup position to avoid screen edges
---@param width integer Popup width
---@param height integer Popup height
---@param relative string Position relative to ("cursor", "win", "editor")
---@param row_offset integer Base row offset
---@param col_offset integer Base column offset
---@return table win_opts Window options with smart positioning
local function calculate_popup_position(width, height, relative, row_offset, col_offset)
	local screen_width = vim.o.columns
	local screen_height = vim.o.lines
	
	local row = row_offset
	local col = col_offset
	
	if relative == "cursor" then
		local cursor_pos = api.nvim_win_get_cursor(0)
		local cursor_row = cursor_pos[1] - 1 -- Convert to 0-based
		local cursor_col = cursor_pos[2]
		
		-- Adjust position if popup would go off screen
		-- Check right edge
		if cursor_col + col + width > screen_width then
			col = screen_width - cursor_col - width - 2
		end
		
		-- Check bottom edge
		if cursor_row + row + height > screen_height - 2 then
			-- Position above cursor instead
			row = -height - 1
		end
		
		-- Ensure minimum boundaries
		col = math.max(col, -cursor_col + 1)
		row = math.max(row, -cursor_row + 1)
		
	elseif relative == "win" then
		local win_width = api.nvim_win_get_width(0)
		local win_height = api.nvim_win_get_height(0)
		
		-- Check boundaries within current window
		if col + width > win_width then
			col = win_width - width - 1
		end
		
		if row + height > win_height then
			row = win_height - height - 1
		end
		
		-- Ensure minimum boundaries
		col = math.max(col, 0)
		row = math.max(row, 0)
	end
	
	return {
		relative = relative,
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
	}
end

---Show content in a popup window
---@param content string|string[] Content to display (string or array of lines)
---@param opts? table Optional configuration overrides
---@return PopupState popup Current popup state
function M.show(content, opts)
	opts = opts or {}
	local config = require("termdebug-simple").config
	if not config then
		vim.notify("termdebug-simple not initialized", vim.log.levels.ERROR)
		return { buf = nil, win = nil }
	end

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

	local win_opts = calculate_popup_position(
		width,
		height,
		config.popup.relative,
		config.popup.row_offset,
		config.popup.col_offset
	)
	
	-- Add additional window options
	win_opts.border = config.popup.border
	win_opts.focusable = config.popup.focusable

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

	-- Store the source buffer (where popup was triggered from)
	local source_buf = vim.api.nvim_get_current_buf()
	
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
		buffer = source_buf,
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
