---@class MarkdownEditorCommands
local M = {}

local config = require("markdown_editor.config")
local headings = require("markdown_editor.headings")

---Demote a markdown heading (increase level number)
function M.demote_heading()
  headings.demote_heading()
end

---Promote a markdown heading (decrease level number)
function M.promote_heading()
  headings.promote_heading()
end

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
  
  -- Create heading manipulation commands
  vim.api.nvim_create_user_command("MarkdownEditorDemoteHeading", function()
    M.demote_heading()
  end, {
    desc = "Demote current markdown heading (increase level)",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorPromoteHeading", function()
    M.promote_heading()
  end, {
    desc = "Promote current markdown heading (decrease level)",
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