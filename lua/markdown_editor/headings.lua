---@class MarkdownEditorHeadings
local M = {}

---Get the treesitter node at cursor position
---@return TSNode|nil
local function get_node_at_cursor()
  local ts_utils = require('nvim-treesitter.ts_utils')
  return ts_utils.get_node_at_cursor(0)
end

---Get the current heading level from treesitter
---@return number|nil level The heading level (1-6) or nil if not a heading
function M.get_heading_level()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  -- Move cursor to beginning of line to get the heading marker
  vim.api.nvim_win_set_cursor(0, { current_pos[1], 0 })
  
  local node = get_node_at_cursor()
  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, current_pos)
  
  if not node then
    return nil
  end
  
  local node_type = node:type()
  local header_levels = {
    atx_h1_marker = 1,
    atx_h2_marker = 2,
    atx_h3_marker = 3,
    atx_h4_marker = 4,
    atx_h5_marker = 5,
    atx_h6_marker = 6,
  }
  
  return header_levels[node_type]
end

---Demote a markdown heading (increase level number)
---@return boolean success Whether the operation was successful
function M.demote_heading()
  local current_level = M.get_heading_level()
  
  if not current_level then
    vim.notify("Cursor is not on a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  if current_level >= 6 then
    vim.notify("Cannot demote heading beyond level 6", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  
  -- Find the heading pattern and add one more #
  local new_line = line:gsub("^(#+)", "%1#")
  
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
  vim.notify(string.format("Heading demoted to level %d", current_level + 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Promote a markdown heading (decrease level number)
---@return boolean success Whether the operation was successful
function M.promote_heading()
  local current_level = M.get_heading_level()
  
  if not current_level then
    vim.notify("Cursor is not on a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  if current_level <= 1 then
    vim.notify("Cannot promote heading beyond level 1", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  
  -- Remove one # from the heading
  local new_line = line:gsub("^#+", function(match) 
    return match:sub(1, -2)
  end)
  
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
  vim.notify(string.format("Heading promoted to level %d", current_level - 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

return M