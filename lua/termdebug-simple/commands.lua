local M = {}
local config = nil
local parser = nil
local popup = nil

function M.setup(cfg)
	config = cfg
	parser = require("termdebug-simple.parser")
	popup = require("termdebug-simple.popup")
end

function M.start_debug_session(args)
	vim.cmd("packadd termdebug")

	local cmd_args = args or ""
	if config.debugger_args then
		if type(config.debugger_args) == "table" then
			cmd_args = table.concat(config.debugger_args, " ")
		else
			cmd_args = config.debugger_args
		end
	end

	if config.debugger ~= "gdb" then
		vim.g.termdebugger = config.debugger
	end

	local full_cmd = "Termdebug"
	if cmd_args and cmd_args ~= "" then
		full_cmd = full_cmd .. " " .. cmd_args
	end

	vim.cmd(full_cmd)
end

local function generate_uuid()
	return config.uuid_marker .. tostring(vim.loop.hrtime())
end

local function send_command_with_uuid(cmd)
	local uuid = generate_uuid()

	vim.fn.TermDebugSendCommand('printf "' .. uuid .. '\\n"')
	vim.fn.TermDebugSendCommand(cmd)
	vim.fn.TermDebugSendCommand('printf "\\n' .. uuid .. '"')

	vim.defer_fn(function()
		local output = parser.extract_between_uuids(uuid)
		if output then
			return output
		end
	end, 100)

	return uuid
end

function M.evaluate_expression()
	local expr = vim.fn.expand("<cexpr>")
	if not expr or expr == "" then
		vim.notify("No expression under cursor", vim.log.levels.WARN)
		return
	end

	local uuid = send_command_with_uuid("p " .. expr)

	vim.defer_fn(function()
		local output = parser.extract_between_uuids(uuid)
		if output then
			local formatted = parser.format_variable_output(output, expr)
			popup.show(formatted)
		else
			vim.notify("Failed to evaluate expression", vim.log.levels.ERROR)
		end
	end, 200)
end

function M.toggle_breakpoint()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_file = vim.fn.expand("%:p")

	local breakpoint_info = current_file .. ":" .. current_line

	local info_uuid = send_command_with_uuid("info breakpoints")

	vim.defer_fn(function()
		local output = parser.extract_between_uuids(info_uuid)
		if output and output:find(breakpoint_info) then
			vim.cmd("Clear")
		else
			vim.cmd("Break")
		end
	end, 200)
end

function M.run_to_cursor()
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local current_file = vim.fn.expand("%:p")

	vim.fn.TermDebugSendCommand("until " .. current_file .. ":" .. current_line)
end

function M.list_breakpoints()
	local uuid = send_command_with_uuid("info breakpoints")

	vim.defer_fn(function()
		local output = parser.extract_between_uuids(uuid)
		if output then
			local formatted = parser.format_breakpoints(output)
			popup.show(formatted, { title = "Breakpoints" })
		else
			vim.notify("Failed to get breakpoints", vim.log.levels.ERROR)
		end
	end, 200)
end

function M.step_into()
	vim.fn.TermDebugSendCommand("step")
end

function M.step_over()
	vim.fn.TermDebugSendCommand("next")
end

function M.step_out()
	vim.fn.TermDebugSendCommand("finish")
end

function M.continue()
	vim.fn.TermDebugSendCommand("continue")
end

function M.stop()
	vim.fn.TermDebugSendCommand("quit")
end

return M

