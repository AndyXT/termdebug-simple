local M = {}

M.config = nil

function M.setup(opts)
	M.config = require("termdebug-simple.config").setup(opts)

	require("termdebug-simple.commands").setup(M.config)
	require("termdebug-simple.keymaps").setup(M.config)

	vim.api.nvim_create_user_command("TermdebugSimpleStart", function(args)
		require("termdebug-simple.commands").start_debug_session(args.args)
	end, { nargs = "*", desc = "Start termdebug session" })

	vim.api.nvim_create_user_command("TermdebugSimpleEval", function()
		require("termdebug-simple.commands").evaluate_expression()
	end, { desc = "Evaluate expression under cursor" })

	vim.api.nvim_create_user_command("TermdebugSimpleBreakpoints", function()
		require("termdebug-simple.commands").list_breakpoints()
	end, { desc = "List all breakpoints" })
end

return M

