---@class MarkdownEditorLists
local M = {}

---Get the treesitter node at cursor position
---@return TSNode|nil
local function get_node_at_cursor()
  local ts_utils = require('nvim-treesitter.ts_utils')
  return ts_utils.get_node_at_cursor(0)
end

---Check if cursor is on a list item
---@return string|nil marker The list marker (-, *, +) or nil if not on a list item
---@return number|nil indent The indentation level of the list item
function M.get_list_item_info()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  
  if not line_content then
    return nil, nil
  end
  
  -- Match list item pattern: optional whitespace, marker (-, *, +), space
  local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
  
  if marker then
    local indent_level = #indent_str
    return marker, indent_level
  end
  
  return nil, nil
end

---Find the parent list item (with less indentation)
---@param current_indent number The indentation level of current item
---@return string|nil marker The parent's marker
---@return number|nil indent The parent's indentation level
---@return number|nil line_num The line number of the parent
local function find_parent_list_item(current_indent)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Search backwards for a list item with less indentation
  for line_num = current_line - 1, 1, -1 do
    local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
    
    if marker then
      local indent_level = #indent_str
      if indent_level < current_indent then
        return marker, indent_level, line_num
      end
    end
  end
  
  return nil, nil, nil
end

---Insert a sibling list item at the same indentation level
---@return boolean success Whether the operation was successful
function M.insert_sibling_list_item()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Create the list item prefix
  local indent_str = string.rep(" ", indent_level)
  local list_prefix = indent_str .. marker .. " "
  
  -- Get current line content after the list marker
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  
  if content_after_marker and content_after_marker ~= "" then
    -- Current line has content, insert new item below
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #list_prefix })
  else
    -- Current line is empty list item, replace it
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line, #list_prefix })
  end
  
  return true
end

---Insert a child list item with increased indentation
---@return boolean success Whether the operation was successful
function M.insert_child_list_item()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Increase indentation (typically 2 or 4 spaces)
  local child_indent = indent_level + 2
  local indent_str = string.rep(" ", child_indent)
  local list_prefix = indent_str .. marker .. " "
  
  -- Get current line content after the list marker
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  
  if content_after_marker and content_after_marker ~= "" then
    -- Current line has content, insert new item below
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #list_prefix })
  else
    -- Current line is empty list item, replace it
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line, #list_prefix })
  end
  
  return true
end

return M