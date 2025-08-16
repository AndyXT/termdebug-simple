---@class TermdebugSimpleCommands
---@field step_into function
---@field step_over function
---@field step_out function
---@field continue function
---@field stop function
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

---Check if termdebug is available and compatible
---@return boolean available True if termdebug is available
---@return string|nil reason Reason why it's not available (if applicable)
local function check_termdebug_availability()
	-- Check Neovim version
	if vim.fn.has("nvim-0.7.0") == 0 then
		return false, "Neovim >= 0.7.0 required"
	end
	
	-- Check if termdebug package exists
	local termdebug_path = vim.fn.findfile("pack/dist/opt/termdebug/plugin/termdebug.vim", vim.o.packpath)
	if termdebug_path == "" then
		return false, "termdebug plugin not found in Neovim installation"
	end
	
	-- Check if GDB is available
	if vim.fn.executable("gdb") == 0 and not config.debugger then
		return false, "GDB not found in PATH and no custom debugger configured"
	end
	
	return true, nil
end

---Start a new debug session with termdebug
---@param args? string Additional arguments to pass to debugger
function M.start_debug_session(args)
	if not config then
		vim.notify("termdebug-simple not initialized", vim.log.levels.ERROR)
		return
	end
	
	-- Check termdebug availability before attempting to load
	local available, reason = check_termdebug_availability()
	if not available then
		vim.notify("Cannot start debug session: " .. reason, vim.log.levels.ERROR)
		return
	end

	local ok, err = pcall(vim.cmd, "packadd termdebug")
	if not ok then
		vim.notify("Failed to load termdebug plugin: " .. tostring(err), vim.log.levels.ERROR)
		vim.notify("Try running ':help termdebug' to check if the plugin is properly installed", vim.log.levels.INFO)
		return
	end

	local cmd_args = args or config.debugger_args or ""
	if type(cmd_args) == "table" then
		cmd_args = table.concat(cmd_args, " ")
	end
	
	-- Sanitize debugger arguments to prevent command injection
	if cmd_args ~= "" then
		-- Allow alphanumeric, spaces, hyphens, dots, underscores, and forward slashes for file paths
		cmd_args = cmd_args:gsub('[^%w%s%._%-%/]', '')
		cmd_args = vim.trim(cmd_args)
	end

	if config.debugger and config.debugger ~= "gdb" then
		-- Sanitize debugger path
		local safe_debugger = config.debugger:gsub('[^%w%s%._%-%/]', '')
		if safe_debugger ~= "" then
			vim.g.termdebugger = safe_debugger
		end
	end

	local success, err = pcall(vim.cmd, "Termdebug" .. (cmd_args ~= "" and " " .. cmd_args or ""))
	if not success then
		vim.notify("Failed to start debug session: " .. tostring(err), vim.log.levels.ERROR)
		-- Provide helpful suggestions
		if tostring(err):match("command not found") then
			vim.notify("Make sure GDB is installed and in your PATH", vim.log.levels.INFO)
		elseif tostring(err):match("No such file") then
			vim.notify("Check that the target executable exists and has debug symbols", vim.log.levels.INFO)
		end
	else
		vim.notify("Debug session started successfully", vim.log.levels.INFO)
	end
end

---Generate a unique UUID for command output parsing
---@return string uuid Unique identifier
local function generate_uuid()
	if not config then
		return "UUID_" .. tostring(vim.loop.hrtime())
	end
	return config.uuid_marker .. tostring(vim.loop.hrtime())
end

---Sanitize GDB command input to prevent injection
---@param cmd string Raw command input
---@return string|nil sanitized Sanitized command, or nil if invalid
local function sanitize_gdb_command(cmd)
	if not cmd or type(cmd) ~= "string" then
		return nil
	end
	
	-- Remove dangerous characters that could break out of GDB context
	cmd = cmd:gsub('[;&|`$(){}]', '')
	
	-- Remove any printf commands that could interfere with our UUID system
	cmd = cmd:gsub('printf', '')
	
	-- Trim whitespace
	cmd = vim.trim(cmd)
	
	-- Check for empty command after sanitization
	if cmd == "" then
		return nil
	end
	
	return cmd
end

---Send a GDB command wrapped with UUID markers
---@param cmd string GDB command to execute
---@return string|nil uuid UUID used for this command, or nil on error
local function send_command_with_uuid(cmd)
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Termdebug not active", vim.log.levels.WARN)
		return nil
	end
	
	-- Sanitize the command
	local sanitized_cmd = sanitize_gdb_command(cmd)
	if not sanitized_cmd then
		vim.notify("Invalid or unsafe GDB command: " .. tostring(cmd), vim.log.levels.ERROR)
		return nil
	end

	local uuid = generate_uuid()

	vim.fn.TermDebugSendCommand('printf "' .. uuid .. '\\n"')
	vim.fn.TermDebugSendCommand(sanitized_cmd)
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

---Execute a GDB command and process its output asynchronously with polling
---@param cmd string GDB command to execute
---@param callback function Function to call with the output
---@param timeout? integer Timeout in milliseconds (default: 5000)
---@param poll_interval? integer Polling interval in milliseconds (default: 50)
local function execute_with_output(cmd, callback, timeout, poll_interval)
	local uuid = send_command_with_uuid(cmd)
	if not uuid then
		callback(nil, "Failed to send command to GDB")
		return
	end

	timeout = timeout or 5000
	poll_interval = poll_interval or 50
	local start_time = vim.loop.hrtime()
	
	local function poll_for_output()
		local output = parser and parser.extract_between_uuids(uuid)
		if output then
			callback(output, nil)
			return
		end
		
		local elapsed = (vim.loop.hrtime() - start_time) / 1e6 -- Convert to milliseconds
		if elapsed >= timeout then
			callback(nil, "Timeout waiting for GDB response after " .. timeout .. "ms")
			return
		end
		
		vim.defer_fn(poll_for_output, poll_interval)
	end
	
	-- Start polling after a short initial delay to let the command execute
	vim.defer_fn(poll_for_output, poll_interval)
end

---Evaluate expression under cursor and show in popup
function M.evaluate_expression()
	local expr = vim.fn.expand("<cexpr>")
	if not expr or expr == "" then
		vim.notify("No expression found under cursor. Place cursor on a variable or expression.", vim.log.levels.WARN)
		return
	end
	
	-- Check if termdebug is active
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Debug session not active. Start debugging with :TermdebugSimpleStart first.", vim.log.levels.ERROR)
		return
	end

	execute_with_output("p " .. expr, function(output, error_msg)
		if output and parser and popup then
			local formatted = parser.format_variable_output(output, expr)
			popup.show(formatted)
		else
			local msg = error_msg or "Failed to evaluate expression"
			vim.notify("Failed to evaluate '" .. expr .. "': " .. msg, vim.log.levels.ERROR)
		end
	end)
end

---Toggle breakpoint at current cursor position
function M.toggle_breakpoint()
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Debug session not active. Start debugging with :TermdebugSimpleStart first.", vim.log.levels.ERROR)
		return
	end
	
	local file, line = get_cursor_position()
	local breakpoint_info = file .. ":" .. line

	execute_with_output("info breakpoints", function(output, error_msg)
		if output then
			if output:find(breakpoint_info) then
				local success, err = pcall(vim.cmd, "Clear")
				if not success then
					vim.notify("Failed to clear breakpoint: " .. tostring(err), vim.log.levels.ERROR)
				end
			else
				local success, err = pcall(vim.cmd, "Break")
				if not success then
					vim.notify("Failed to set breakpoint: " .. tostring(err), vim.log.levels.ERROR)
				end
			end
		else
			vim.notify("Failed to check breakpoints: " .. (error_msg or "Unknown error"), vim.log.levels.ERROR)
			-- Fallback: try to toggle anyway
			local success, err = pcall(vim.cmd, "Break")
			if not success then
				vim.notify("Fallback breakpoint toggle failed: " .. tostring(err), vim.log.levels.ERROR)
			end
		end
	end)
end

---Run program until it reaches cursor position
function M.run_to_cursor()
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Debug session not active. Start debugging with :TermdebugSimpleStart first.", vim.log.levels.ERROR)
		return
	end

	local file, line = get_cursor_position()
	if file == "" then
		vim.notify("No file currently open. Open a source file and place cursor on target line.", vim.log.levels.WARN)
		return
	end
	
	-- Check if file exists and is readable
	if vim.fn.filereadable(file) == 0 then
		vim.notify("File not found or not readable: " .. file, vim.log.levels.ERROR)
		return
	end

	vim.fn.TermDebugSendCommand("until " .. file .. ":" .. line)
	vim.notify("Running to " .. vim.fn.fnamemodify(file, ":t") .. ":" .. line, vim.log.levels.INFO)
end

---List all breakpoints in a popup window
function M.list_breakpoints()
	if not vim.fn.exists("*TermDebugSendCommand") then
		vim.notify("Debug session not active. Start debugging with :TermdebugSimpleStart first.", vim.log.levels.ERROR)
		return
	end
	
	execute_with_output("info breakpoints", function(output, error_msg)
		if output and parser and popup then
			local formatted = parser.format_breakpoints(output)
			popup.show(formatted, { title = "Breakpoints" })
		else
			local msg = error_msg or "Failed to retrieve breakpoint information from GDB"
			vim.notify("Failed to list breakpoints: " .. msg, vim.log.levels.ERROR)
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
			vim.notify("Debug session not active. Start debugging with :TermdebugSimpleStart first.", vim.log.levels.ERROR)
			return
		end
		vim.fn.TermDebugSendCommand(cmd)
	end
end

return M
