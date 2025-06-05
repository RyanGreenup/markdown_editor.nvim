---@class MyPluginCommands
local M = {}

local config = require("myplugin.config")

---Setup plugin commands
---@param opts MyPluginConfig
function M.setup(opts)
  -- Create a user command for the greeting
  vim.api.nvim_create_user_command("MyPluginGreet", function()
    M.greet()
  end, {
    desc = "Display a greeting from MyPlugin",
  })
  
  -- Create a toggle command
  vim.api.nvim_create_user_command("MyPluginToggle", function()
    M.toggle()
  end, {
    desc = "Toggle MyPlugin on/off",
  })
end

---Display a greeting message
function M.greet()
  local greeting = config.get("greeting")
  vim.notify(greeting, vim.log.levels.INFO, { title = "MyPlugin" })
end

---Toggle the plugin state
function M.toggle()
  local current_state = config.get("enabled")
  local new_state = not current_state
  
  -- Update the configuration
  config.options.enabled = new_state
  
  local status = new_state and "enabled" or "disabled"
  vim.notify("MyPlugin " .. status, vim.log.levels.INFO, { title = "MyPlugin" })
end

return M