---@class MarkdownEditorLists
local M = {}

local config = require("markdown_editor.config")

---Get the configured list indentation
---@return number The number of spaces for list indentation
local function get_indent_size()
  return config.get("list_indent") or 2
end

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
  
  -- Increase indentation by configured amount
  local indent_size = get_indent_size()
  local child_indent = indent_level + indent_size
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

---Find all child list items under a parent list item
---@param parent_line number The line number of the parent list item (1-indexed)
---@param parent_indent number The indentation level of the parent
---@return number[] child_lines Array of line numbers containing child list items
local function find_child_list_items(parent_line, parent_indent)
  local child_lines = {}
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Start searching from the line after the parent
  for line_num = parent_line + 1, total_lines do
    local line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
    
    -- Check if line is empty or doesn't have content
    if not line_content or line_content:match("^%s*$") then
      goto continue
    end
    
    -- Check if it's a list item
    local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
    
    if marker then
      local indent_level = #indent_str
      
      -- If we find a list item at the same or less indentation, we've left the parent's section
      if indent_level <= parent_indent then
        break
      end
      
      -- This is a child list item (indent_level > parent_indent)
      table.insert(child_lines, line_num)
    else
      -- Non-list line - check if it's indented enough to be part of the current item
      local line_indent = #(line_content:match("^(%s*)") or "")
      if line_indent <= parent_indent then
        break
      end
    end
    
    ::continue::
  end
  
  return child_lines
end

---Promote a list item (decrease indentation)
---@return boolean success Whether the operation was successful
function M.promote_list_item()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  if indent_level <= 0 then
    vim.notify("Cannot promote list item beyond left margin", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  
  -- Decrease indentation by configured amount
  local indent_size = get_indent_size()
  local new_indent = math.max(0, indent_level - indent_size)
  local new_indent_str = string.rep(" ", new_indent)
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  local new_line = new_indent_str .. marker .. " " .. (content_after_marker or "")
  
  vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
  
  -- Adjust cursor position
  local col_adjustment = indent_level - new_indent
  local new_col = math.max(0, current_col - col_adjustment)
  vim.api.nvim_win_set_cursor(0, { current_line, new_col })
  
  vim.notify(string.format("List item promoted (indent: %d)", new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Demote a list item (increase indentation)
---@return boolean success Whether the operation was successful
function M.demote_list_item()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  
  -- Increase indentation by configured amount
  local indent_size = get_indent_size()
  local new_indent = indent_level + indent_size
  local new_indent_str = string.rep(" ", new_indent)
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  local new_line = new_indent_str .. marker .. " " .. (content_after_marker or "")
  
  vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
  
  -- Adjust cursor position
  local col_adjustment = new_indent - indent_level
  local new_col = current_col + col_adjustment
  vim.api.nvim_win_set_cursor(0, { current_line, new_col })
  
  vim.notify(string.format("List item demoted (indent: %d)", new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Promote a list item and all its children (decrease indentation)
---@return boolean success Whether the operation was successful
function M.promote_list_item_with_children()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  if indent_level <= 0 then
    vim.notify("Cannot promote list item beyond left margin", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Find all child list items
  local child_lines = find_child_list_items(current_line, indent_level)
  
  -- Promote the parent list item first
  local indent_size = get_indent_size()
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local new_indent = math.max(0, indent_level - indent_size)
  local new_indent_str = string.rep(" ", new_indent)
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  local new_line = new_indent_str .. marker .. " " .. (content_after_marker or "")
  vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
  
  -- Promote all child list items
  for _, child_line in ipairs(child_lines) do
    local child_line_content = vim.api.nvim_buf_get_lines(0, child_line - 1, child_line, false)[1]
    local child_indent_str, child_marker = child_line_content:match("^(%s*)([-*+])%s")
    
    if child_marker then
      local child_indent = #child_indent_str
      local new_child_indent = math.max(0, child_indent - indent_size)
      local new_child_indent_str = string.rep(" ", new_child_indent)
      local child_content = child_line_content:match("^%s*[-*+]%s*(.*)")
      local new_child_line = new_child_indent_str .. child_marker .. " " .. (child_content or "")
      vim.api.nvim_buf_set_lines(0, child_line - 1, child_line, false, { new_child_line })
    end
  end
  
  -- Adjust cursor position
  local col_adjustment = indent_level - new_indent
  local new_col = math.max(0, current_col - col_adjustment)
  vim.api.nvim_win_set_cursor(0, { current_line, new_col })
  
  local child_count = #child_lines
  if child_count > 0 then
    vim.notify(string.format("List item and %d children promoted (indent: %d)", child_count, new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    vim.notify(string.format("List item promoted (indent: %d)", new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

---Demote a list item and all its children (increase indentation)
---@return boolean success Whether the operation was successful
function M.demote_list_item_with_children()
  local marker, indent_level = M.get_list_item_info()
  
  if not marker then
    return false -- Not on a list item
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Find all child list items
  local child_lines = find_child_list_items(current_line, indent_level)
  
  -- Demote the parent list item first
  local indent_size = get_indent_size()
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
  local new_indent = indent_level + indent_size
  local new_indent_str = string.rep(" ", new_indent)
  local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
  local new_line = new_indent_str .. marker .. " " .. (content_after_marker or "")
  vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
  
  -- Demote all child list items
  for _, child_line in ipairs(child_lines) do
    local child_line_content = vim.api.nvim_buf_get_lines(0, child_line - 1, child_line, false)[1]
    local child_indent_str, child_marker = child_line_content:match("^(%s*)([-*+])%s")
    
    if child_marker then
      local child_indent = #child_indent_str
      local new_child_indent = child_indent + indent_size
      local new_child_indent_str = string.rep(" ", new_child_indent)
      local child_content = child_line_content:match("^%s*[-*+]%s*(.*)")
      local new_child_line = new_child_indent_str .. child_marker .. " " .. (child_content or "")
      vim.api.nvim_buf_set_lines(0, child_line - 1, child_line, false, { new_child_line })
    end
  end
  
  -- Adjust cursor position
  local col_adjustment = new_indent - indent_level
  local new_col = current_col + col_adjustment
  vim.api.nvim_win_set_cursor(0, { current_line, new_col })
  
  local child_count = #child_lines
  if child_count > 0 then
    vim.notify(string.format("List item and %d children demoted (indent: %d)", child_count, new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    vim.notify(string.format("List item demoted (indent: %d)", new_indent), vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

return M