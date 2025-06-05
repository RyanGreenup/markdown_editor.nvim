# Neovim Lua Plugin Template

A minimal, template for creating Neovim plugins in Lua with lazy.nvim support.

## Features

- Ready to use structure
- Type annotations
- Registers Vim Commands
- Supports lazy.nvim

## Quick Start

1. Create a git repository for the plugin
2. Clone this repo
3. Run `just init '<plugin_name>.nvim' '<username>' 'https://github.com/<username>/<plugin_name>.nvim'

## Overview

### 1. Use This Template

```bash
PLUGIN_NAME="my-awesome-plugin"
USERNAME="your-username"

# Clone or copy this repository structure
git clone https://github.com/RyanGreenup/nvim-plugin-template my-awesome-plugin
cd my-awesome-plugin

# Move the git repository to your own upstream repository
git remote set-url origin "https://github.com/"${USERNAME}"/my-awesome-plugin.git"
```

### 2. Install the Template Plugin

Install the plugin to make sure it works

```lua
{
  "ryangreenup/nvim-plugin-template",
  config = function()
    require("myplugin").setup({
      greeting = "Hello from my awesome plugin!",
      enabled = true,
    })
  end,
}
```

Then in vim

```vim
:MyPluginGreet

```


### 2. Rename the Plugin

Use the provided automation script to rename the plugin:

```bash
# Using just (recommended)
just init my-awesome-plugin your-username https://github.com/your-username/my-awesome-plugin.git

# Or directly with Python
python3 scripts/rename_plugin.py my-awesome-plugin your-username https://github.com/your-username/my-awesome-plugin.git
```

This will:
- Rename the `lua/myplugin` directory to `lua/my_awesome_plugin`
- Update all references throughout the codebase
- Set up the git remote origin (if URL provided)
- Convert between naming conventions (kebab-case, snake_case, CamelCase)

### 3. Install with lazy.nvim

Add to your Neovim configuration:

```lua
{
  "your-username/your-plugin-name.nvim",
  config = function()
    require("your-plugin-name").setup({
      greeting = "Hello from my awesome plugin!",
      enabled = true,
    })
  end,
}
```

## Plugin Structure

```
├── lua/
│   └── myplugin/
│       ├── init.lua        # Main plugin entry point
│       ├── config.lua      # Configuration management
│       └── commands.lua    # User commands
├── scripts/
│   └── rename_plugin.py   # Automation script for renaming
├── justfile               # Task runner with commands
├── lazy.lua              # Example lazy.nvim package spec
└── README.md             # This file
```

### File Breakdown

- **`init.lua`**: Main plugin module with `setup()` function
- **`config.lua`**: Handles plugin configuration and options
- **`commands.lua`**: Defines user commands and their implementations
- **`lazy.lua`**: Example configuration for lazy.nvim users
- **`justfile`**: Task runner with helpful commands (requires [just](https://github.com/casey/just))
- **`scripts/rename_plugin.py`**: Automation script for renaming the template

## Development Guide

### Adding New Features

1. **New Module**: Create a new file in `lua/myplugin/`
2. **Require in init.lua**: Add `require("myplugin.new-module")`
3. **Initialize in setup()**: Call module's setup function if needed

### Configuration Pattern


```lua
-- In your new module
local config = require("myplugin.config")

function M.some_function()
  local my_option = config.get("my_option")
  -- Use the option
end
```

### Adding Commands

```lua
-- In commands.lua
vim.api.nvim_create_user_command("MyNewCommand", function()
  M.my_new_function()
end, {
  desc = "Description of the command",
})
```

## Best Practices

1. Prefix all global functions and veriables
2. Use `vim.tbl_deep_extend()` for merging configs
3. Handle errors with a warning
    ```lua
    local ok, result = pcall(some_function)
    if not ok then
      vim.notify("Error: " .. result, vim.log.levels.ERROR)
      return
    end
    ```
4. Use `vim.schedule()` for jobs that can wait
5. Cache computations
6. Write Documentation as you go
7. Allow default keybindings to be:
    1. Disabled
    2. Remapped


