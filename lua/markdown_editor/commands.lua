---@class MarkdownEditorCommands
local M = {}

local config = require("markdown_editor.config")

---Setup plugin commands
---@param opts MarkdownEditorConfig
function M.setup(opts)
  -- Create a user command for the greeting
  vim.api.nvim_create_user_command("MarkdownEditorGreet", function()
    M.greet()
  end, {
    desc = "Display a greeting from MarkdownEditor",
  })
  
  -- Create a toggle command
  vim.api.nvim_create_user_command("MarkdownEditorToggle", function()
    M.toggle()
  end, {
    desc = "Toggle MarkdownEditor on/off",
  })
end

---Display a greeting message
function M.greet()
  local greeting = config.get("greeting")
  vim.notify(greeting, vim.log.levels.INFO, { title = "MarkdownEditor" })
end

---Toggle the plugin state
function M.toggle()
  local current_state = config.get("enabled")
  local new_state = not current_state
  
  -- Update the configuration
  config.options.enabled = new_state
  
  local status = new_state and "enabled" or "disabled"
  vim.notify("MarkdownEditor " .. status, vim.log.levels.INFO, { title = "MarkdownEditor" })
end

return M