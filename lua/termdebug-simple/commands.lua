---@class TermdebugSimpleCommands
local M = {}

---@type TermdebugSimpleConfig|nil
local config = nil
---@type table|nil
local parser = nil
---@type table|nil
local popup = nil

---Initialize commands module with configuration
---@param cfg TermdebugSimpleConfig Plugin configuration
function M.setup(cfg)
	config = cfg
	parser = require("termdebug-simple.parser")
	popup = require("termdebug-simple.popup")
end

---Start a new debug session with termdebug
---@param args? string Additional arguments to pass to debugger
function M.start_debug_session(args)
	if not config then
		vim.notify("termdebug-simple not initialized", vim.log.levels.ERROR)
		return
	end

	local ok, _ = pcall(vim.cmd, "packadd termdebug")
	if not ok then
		vim.notify("Failed to load termdebug", vim.log.levels.ERROR)
		return
	end

	local cmd_args = args or config.debugger_args or ""
	if type(cmd_args) == "table" then
		cmd_args = table.concat(cmd_args, " ")
	end

	if config.debugger ~= "gdb" then
		vim.g.termdebugger = config.debugger
	end

	local success, err = pcall(vim.cmd, "Termdebug" .. (cmd_args ~= "" and " " .. cmd_args or ""))
	if not success then
		vim.notify("Failed to start debug session: " .. tostring(err), vim.log.levels.ERROR)
	end
end

---Generate a unique UUID for command output parsing
---@return string uuid Unique identifier
local function generate_uuid()
	return config.uuid_marker .. tostring(vim.loop.hrtime())
end

---Send a GDB command wrapped with UUID markers
---@param cmd string GDB command to execute
---@return string|nil uuid UUID used for this command, or nil on error
local function send_command_with_uuid(cmd)
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Termdebug not active", vim.log.levels.WARN)
		return nil
	end

	local uuid = generate_uuid()

	vim.fn.TermDebugSendCommand('printf "' .. uuid .. '\\n"')
	vim.fn.TermDebugSendCommand(cmd)
	vim.fn.TermDebugSendCommand('printf "\\n' .. uuid .. '"')

	return uuid
end

---Get current cursor position in the buffer
---@return string file Full path to current file
---@return integer line Current line number
local function get_cursor_position()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local file = vim.fn.expand("%:p")
	return file, line
end

---Execute a GDB command and process its output asynchronously
---@param cmd string GDB command to execute
---@param callback function Function to call with the output
---@param delay? integer Delay in milliseconds (default: 200)
local function execute_with_output(cmd, callback, delay)
	local uuid = send_command_with_uuid(cmd)
	if not uuid then
		callback(nil)
		return
	end

	vim.defer_fn(function()
		local output = parser.extract_between_uuids(uuid)
		callback(output)
	end, delay or 200)
end

---Evaluate expression under cursor and show in popup
function M.evaluate_expression()
	local expr = vim.fn.expand("<cexpr>")
	if not expr or expr == "" then
		vim.notify("No expression under cursor", vim.log.levels.WARN)
		return
	end

	execute_with_output("p " .. expr, function(output)
		if output then
			local formatted = parser.format_variable_output(output, expr)
			popup.show(formatted)
		else
			vim.notify("Failed to evaluate expression", vim.log.levels.ERROR)
		end
	end)
end

---Toggle breakpoint at current cursor position
function M.toggle_breakpoint()
	local file, line = get_cursor_position()
	local breakpoint_info = file .. ":" .. line

	execute_with_output("info breakpoints", function(output)
		if output and output:find(breakpoint_info) then
			vim.cmd("Clear")
		else
			vim.cmd("Break")
		end
	end)
end

---Run program until it reaches cursor position
function M.run_to_cursor()
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Termdebug not active", vim.log.levels.WARN)
		return
	end

	local file, line = get_cursor_position()
	if file == "" then
		vim.notify("No file open", vim.log.levels.WARN)
		return
	end

	vim.fn.TermDebugSendCommand("until " .. file .. ":" .. line)
end

---List all breakpoints in a popup window
function M.list_breakpoints()
	execute_with_output("info breakpoints", function(output)
		if output then
			local formatted = parser.format_breakpoints(output)
			popup.show(formatted, { title = "Breakpoints" })
		else
			vim.notify("Failed to get breakpoints", vim.log.levels.ERROR)
		end
	end)
end

local simple_commands = {
	step_into = "step",
	step_over = "next",
	step_out = "finish",
	continue = "continue",
	stop = "quit"
}

for name, cmd in pairs(simple_commands) do
	M[name] = function()
		if not vim.fn.exists("*TermDebugSendCommand") then
			vim.notify("Termdebug not active", vim.log.levels.WARN)
			return
		end
		vim.fn.TermDebugSendCommand(cmd)
	end
end

return M
