---@class MarkdownEditor
---@field config MarkdownEditorConfig
local M = {}

local config = require("markdown_editor.config")
local commands = require("markdown_editor.commands")

---@class MarkdownEditorConfig
---@field greeting string: The greeting message to display
---@field enabled boolean: Whether the plugin is enabled
---@field list_indent number: Number of spaces for list indentation (default: 2)
---@field auto_indent_lists boolean: Auto-indent when creating new lines in lists (default: true)
local default_config = {
  greeting = "Hello from MarkdownEditor!",
  enabled = true,
  list_indent = 2,
  auto_indent_lists = true,
}

---Setup function called by lazy.nvim
---@param opts? MarkdownEditorConfig: User configuration options
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