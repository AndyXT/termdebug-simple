# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

termdebug-simple is a Neovim plugin that enhances the built-in termdebug with Eclipse-compatible keymaps and popup displays for GDB debugging. It provides a clean Lua implementation following modern Neovim patterns.

## Architecture

The plugin follows a modular Lua architecture:

- **Entry point**: `plugin/termdebug-simple.lua` - Standard Neovim plugin loader
- **Main module**: `lua/termdebug-simple/init.lua` - Plugin initialization and user commands
- **Core modules**:
  - `config.lua` - Configuration management with type annotations
  - `commands.lua` - GDB command wrappers and debugging functions
  - `parser.lua` - GDB output parsing with UUID-based isolation
  - `popup.lua` - Floating window management for variable display
  - `keymaps.lua` - Eclipse-compatible and custom key bindings

## Key Concepts

### UUID-Based Output Parsing
The plugin uses UUID markers to isolate GDB command output for accurate parsing. Commands are wrapped with `printf` statements containing unique UUIDs to identify specific command responses in the GDB terminal buffer.

### Asynchronous Operations
GDB commands that require output parsing use `vim.defer_fn()` with configurable delays (default 200ms) to allow GDB output to be captured before processing.

### Configuration System
Uses Lua type annotations (`---@class`, `---@field`) for IDE support. Configuration merges user options with defaults using `vim.tbl_deep_extend`.

## Development

### File Structure
```
lua/termdebug-simple/
├── init.lua         # Main plugin interface
├── config.lua       # Configuration with type annotations
├── commands.lua     # GDB command implementations
├── parser.lua       # Output parsing logic
├── popup.lua        # Floating window management
└── keymaps.lua      # Key binding setup
```

### Code Style
- Uses LuaLS type annotations throughout
- Modular design with clear separation of concerns
- Error handling with `pcall` and user notifications
- Modern Neovim API patterns (nvim_create_user_command, nvim_win_*, etc.)

### Dependencies
- Neovim >= 0.7.0
- Built-in termdebug plugin
- GDB debugger

### No Build System
This is a pure Lua plugin with no build, test, or lint scripts. Development involves direct Lua file editing and testing within Neovim.

### Testing
Manual testing within Neovim by:
1. Loading the plugin in a test environment
2. Opening a C/C++ project with debugging symbols
3. Testing debugging commands and popup displays
4. Verifying Eclipse-compatible keymaps work correctly