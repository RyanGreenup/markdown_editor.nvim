---@class MyPlugin
---@field config MyPluginConfig
local M = {}

local config = require("myplugin.config")
local commands = require("myplugin.commands")

---@class MyPluginConfig
---@field greeting string: The greeting message to display
---@field enabled boolean: Whether the plugin is enabled
local default_config = {
  greeting = "Hello from MyPlugin!",
  enabled = true,
}

---Setup function called by lazy.nvim
---@param opts? MyPluginConfig: User configuration options
function M.setup(opts)
  opts = opts or {}
  
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", default_config, opts)
  
  -- Initialize the plugin if enabled
  if M.config.enabled then
    config.setup(M.config)
    commands.setup(M.config)
  end
end

return M