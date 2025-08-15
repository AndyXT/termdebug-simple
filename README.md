# termdebug-simple

A simple Neovim plugin that enhances the built-in termdebug with better keymaps and popup displays for GDB debugging.

## Features

- Eclipse-compatible debugging keymaps (F5-F9)
- Variable evaluation with hover-like popup display
- Breakpoint management with toggle functionality
- Run to cursor functionality
- Breakpoint listing in popup window
- Clean Lua implementation following modern Neovim patterns

## Requirements

- Neovim >= 0.7.0
- GDB installed on your system
- termdebug (included with Neovim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/termdebug-simple",
  keys = {
    { "<F5>", desc = "Debug: Step Into" },
    { "<F6>", desc = "Debug: Step Over" },
    { "<F7>", desc = "Debug: Step Out" },
    { "<F8>", desc = "Debug: Continue" },
    { "<F9>", desc = "Debug: Toggle Breakpoint" },
    { "<leader>mK", desc = "Debug: Evaluate Variable" },
    { "<leader>mb", desc = "Debug: Toggle Breakpoint" },
    { "<leader>ms", desc = "Debug: Start Session" },
  },
  config = function()
    require("termdebug-simple").setup({
      -- your configuration
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/termdebug-simple",
  config = function()
    require("termdebug-simple").setup({
      -- your configuration
    })
  end
}
```

## Configuration

Default configuration:

```lua
require("termdebug-simple").setup({
  debugger = "gdb",                    -- Debugger executable
  debugger_args = "-x .gdbinit",       -- Arguments to pass to debugger
  keymap_prefix = "<leader>m",         -- Prefix for non-Eclipse keymaps
  eclipse_keymaps = true,              -- Enable Eclipse-style F-key mappings
  popup = {
    border = "rounded",               -- Border style for popup windows
    width = 60,                       -- Popup window width
    height = 10,                      -- Maximum popup window height
    relative = "cursor",              -- Position relative to cursor
    row_offset = 1,                   -- Row offset from cursor
    col_offset = 0,                   -- Column offset from cursor
    focusable = true,                 -- Allow focusing the popup
    scrollable = true,                -- Enable scrolling in popup
  },
  uuid_marker = "TERMDEBUG_SIMPLE_UUID_", -- UUID marker for output parsing
})
```

## Usage

### Starting a Debug Session

1. Start a debug session:
   ```vim
   :TermdebugSimpleStart
   ```
   Or use the keymap: `<leader>ms`

2. The plugin will automatically load termdebug and start GDB with your configured arguments.

### Keymaps

#### Eclipse-compatible debugging keys (when `eclipse_keymaps = true`):
- `<F5>` - Step Into
- `<F6>` - Step Over  
- `<F7>` - Step Out
- `<F8>` - Continue
- `<F9>` - Toggle Breakpoint
- `<Shift-F5>` - Stop debugging

#### Additional keymaps (with default prefix `<leader>m`):
- `<leader>mK` - Evaluate variable under cursor (shows in popup)
- `<leader>mb` - Toggle breakpoint at cursor
- `<leader>mr` - Run to cursor
- `<leader>ml` - List all breakpoints
- `<leader>ms` - Start debug session
- `<leader>mi` - Step into
- `<leader>mo` - Step over
- `<leader>mu` - Step out (up)
- `<leader>mc` - Continue
- `<leader>mq` - Quit/stop debugging

### Commands

- `:TermdebugSimpleStart [args]` - Start a debug session with optional arguments
- `:TermdebugSimpleEval` - Evaluate expression under cursor
- `:TermdebugSimpleBreakpoints` - List all breakpoints

## How It Works

The plugin enhances Neovim's built-in termdebug by:

1. **Smart Output Parsing**: Uses UUID markers to isolate GDB command output for accurate parsing
2. **Popup Windows**: Displays variable values and breakpoint lists in floating windows similar to LSP hover
3. **Simplified Keymaps**: Provides both Eclipse-compatible and custom keymaps for common debugging operations
4. **Clean Integration**: Works seamlessly with existing termdebug functionality

## Example Workflow

```vim
" 1. Open your C/C++ file
:e main.c

" 2. Start debugging
:TermdebugSimpleStart ./my_program

" 3. Set breakpoints with F9 or <leader>mb

" 4. Run the program (in GDB window)
(gdb) run

" 5. When breakpoint hits:
"    - F6 to step over
"    - F5 to step into functions
"    - <leader>mK on variables to see their values
"    - F8 to continue execution
```

## Tips

- Create a `.gdbinit` file in your project root for project-specific GDB settings
- The popup windows support scrolling if content exceeds the window size
- Press `q` or `<Esc>` to close popup windows
- Variable evaluation works with complex expressions, not just simple variable names

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Credits

Built on top of Neovim's excellent built-in termdebug plugin.