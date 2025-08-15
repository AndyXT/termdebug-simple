local M = {}

local function find_gdb_buffer()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name:match("gdb") or name:match("debugger") then
			return buf
		end
	end

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		if ft == "gdb" or ft == "termdebug" then
			return buf
		end
	end

	return nil
end

function M.extract_between_uuids(uuid)
	local gdb_buf = find_gdb_buffer()
	if not gdb_buf then
		return nil
	end

	local lines = vim.api.nvim_buf_get_lines(gdb_buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	local pattern = uuid .. "\n(.-)\n" .. uuid
	local match = content:match(pattern)

	if match then
		return vim.trim(match)
	end

	pattern = uuid .. "(.-)" .. uuid
	match = content:match(pattern)
	if match then
		return vim.trim(match)
	end

	return nil
end

function M.format_variable_output(output, var_name)
	if not output then
		return var_name .. " = <error>"
	end

	local pattern = "%$%d+ = (.+)"
	local value = output:match(pattern)

	if value then
		return var_name .. " = " .. value
	end

	pattern = "= (.+)"
	value = output:match(pattern)
	if value then
		return var_name .. " = " .. value
	end

	return var_name .. " = " .. output
end

function M.format_breakpoints(output)
	if not output then
		return "No breakpoints set"
	end

	local lines = vim.split(output, "\n")
	local formatted = {}

	for _, line in ipairs(lines) do
		if line:match("^%d+") then
			local num = line:match("^(%d+)")
			local type = line:match("breakpoint") or line:match("watchpoint") or "unknown"
			local location = line:match("at (.+)") or line:match("in (.+)") or ""

			table.insert(formatted, string.format("#%s %s at %s", num, type, location))
		elseif line:match("at .+:%d+") then
			table.insert(formatted, "  " .. line)
		end
	end

	if #formatted == 0 then
		return "No breakpoints set"
	end

	return table.concat(formatted, "\n")
end

function M.parse_gdb_response(response)
	response = vim.trim(response or "")

	if response:match("^%$%d+") then
		return response:match("^%$%d+ = (.+)")
	end

	if response:match("^=") then
		return response:match("^= (.+)")
	end

	return response
end

return M

