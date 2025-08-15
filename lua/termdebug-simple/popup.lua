local M = {}
local api = vim.api

local current_popup = {
	buf = nil,
	win = nil,
}

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
		if #line > width - 2 then
			lines[i] = string.sub(line, 1, width - 5) .. "..."
		end
	end

	current_popup.buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(current_popup.buf, 0, -1, false, lines)
	api.nvim_buf_set_option(current_popup.buf, "modifiable", false)
	api.nvim_buf_set_option(current_popup.buf, "buftype", "nofile")

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

	api.nvim_buf_set_keymap(current_popup.buf, "n", "q", "", {
		callback = close_popup,
		noremap = true,
		silent = true,
		desc = "Close popup",
	})

	api.nvim_buf_set_keymap(current_popup.buf, "n", "<Esc>", "", {
		callback = close_popup,
		noremap = true,
		silent = true,
		desc = "Close popup",
	})

	if config.popup.scrollable then
		api.nvim_win_set_option(current_popup.win, "wrap", false)
		api.nvim_win_set_option(current_popup.win, "scrolloff", 0)
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

function M.close()
	close_popup()
end

return M

