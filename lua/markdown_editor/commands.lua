---@class MarkdownEditorCommands
local M = {}

local config = require("markdown_editor.config")
local headings = require("markdown_editor.headings")
local reorder = require("markdown_editor.reorder")
local links = require("markdown_editor.links")
local navigation = require("markdown_editor.navigation")

---Demote a markdown heading (increase level number)
function M.demote_heading()
  headings.demote_heading()
end

---Promote a markdown heading (decrease level number)
function M.promote_heading()
  headings.promote_heading()
end

---Demote a markdown heading and all its children (increase level numbers)
function M.demote_heading_with_children()
  headings.demote_heading_with_children()
end

---Promote a markdown heading and all its children (decrease level numbers)
function M.promote_heading_with_children()
  headings.promote_heading_with_children()
end

---Insert a sibling heading at the same level as the nearest parent heading
function M.insert_sibling_heading()
  headings.insert_sibling_heading()
end

---Insert a child heading one level deeper than the nearest parent heading
function M.insert_child_heading()
  headings.insert_child_heading()
end

---Move current heading up (swap with previous sibling)
function M.move_heading_up()
  reorder.move_heading_up()
end

---Move current heading down (swap with next sibling)
function M.move_heading_down()
  reorder.move_heading_down()
end

---Smart link function that creates or edits links based on cursor context
---@param visual_mode boolean|nil Whether called from visual mode
function M.smart_link(visual_mode)
  links.smart_link(visual_mode)
end

---Navigate to the next heading at the same level
function M.next_sibling_heading()
  navigation.next_sibling_heading()
end

---Navigate to the previous heading at the same level
function M.previous_sibling_heading()
  navigation.previous_sibling_heading()
end

---Navigate to the next heading at any level
function M.next_heading()
  navigation.next_heading()
end

---Navigate to the previous heading at any level
function M.previous_heading()
  navigation.previous_heading()
end

---Navigate to the parent heading
function M.parent_heading()
  navigation.parent_heading()
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
  
  vim.api.nvim_create_user_command("MarkdownEditorDemoteHeadingWithChildren", function()
    M.demote_heading_with_children()
  end, {
    desc = "Demote current markdown heading and all its children (increase levels)",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorPromoteHeadingWithChildren", function()
    M.promote_heading_with_children()
  end, {
    desc = "Promote current markdown heading and all its children (decrease levels)",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorInsertSiblingHeading", function()
    M.insert_sibling_heading()
  end, {
    desc = "Insert a sibling heading at the same level as the nearest parent",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorInsertChildHeading", function()
    M.insert_child_heading()
  end, {
    desc = "Insert a child heading one level deeper than the nearest parent",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorMoveHeadingUp", function()
    M.move_heading_up()
  end, {
    desc = "Move current heading up (swap with previous sibling)",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorMoveHeadingDown", function()
    M.move_heading_down()
  end, {
    desc = "Move current heading down (swap with next sibling)",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorSmartLink", function(opts)
    -- Check if command was called from visual mode
    local visual_mode = opts.range == 2
    M.smart_link(visual_mode)
  end, {
    range = true,
    desc = "Create or edit markdown link based on cursor context",
  })
  
  -- Navigation commands
  vim.api.nvim_create_user_command("MarkdownEditorNextSiblingHeading", function()
    M.next_sibling_heading()
  end, {
    desc = "Navigate to next heading at same level",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorPreviousSiblingHeading", function()
    M.previous_sibling_heading()
  end, {
    desc = "Navigate to previous heading at same level",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorNextHeading", function()
    M.next_heading()
  end, {
    desc = "Navigate to next heading at any level",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorPreviousHeading", function()
    M.previous_heading()
  end, {
    desc = "Navigate to previous heading at any level",
  })
  
  vim.api.nvim_create_user_command("MarkdownEditorParentHeading", function()
    M.parent_heading()
  end, {
    desc = "Navigate to parent heading",
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