---@class MarkdownEditorHeadings
local M = {}

---Get the treesitter node at cursor position
---@return TSNode|nil
local function get_node_at_cursor()
  local ts_utils = require('nvim-treesitter.ts_utils')
  return ts_utils.get_node_at_cursor(0)
end

---Get the heading level from a line number
---@param line_num number The line number (1-indexed)
---@return number|nil level The heading level (1-6) or nil if not a heading
local function get_heading_level_at_line(line_num)
  local current_pos = vim.api.nvim_win_get_cursor(0)
  -- Move cursor to beginning of the specified line
  vim.api.nvim_win_set_cursor(0, { line_num, 0 })
  
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

---Get the current heading level from treesitter
---@return number|nil level The heading level (1-6) or nil if not a heading
function M.get_heading_level()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  return get_heading_level_at_line(line_num)
end

---Find all child headings under a parent heading
---@param parent_line number The line number of the parent heading (1-indexed)
---@param parent_level number The level of the parent heading
---@return number[] child_lines Array of line numbers containing child headings
local function find_child_headings(parent_line, parent_level)
  local child_lines = {}
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Start searching from the line after the parent
  for line_num = parent_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    
    if level then
      -- If we find a heading at the same or higher level, we've left the parent's section
      if level <= parent_level then
        break
      end
      
      -- This is a child heading (level > parent_level)
      table.insert(child_lines, line_num)
    end
  end
  
  return child_lines
end

---Find the parent heading for the current cursor position
---@return number|nil parent_line The line number of the parent heading
---@return number|nil parent_level The level of the parent heading
local function find_parent_heading()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Search backwards from current line to find a heading
  for line_num = current_line, 1, -1 do
    local level = get_heading_level_at_line(line_num)
    if level then
      return line_num, level
    end
  end
  
  return nil, nil
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

---Demote a markdown heading and all its children (increase level numbers)
---@return boolean success Whether the operation was successful
function M.demote_heading_with_children()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local current_level = M.get_heading_level()
  
  if not current_level then
    vim.notify("Cursor is not on a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  if current_level >= 6 then
    vim.notify("Cannot demote heading beyond level 6", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Find all child headings
  local child_lines = find_child_headings(line_num, current_level)
  
  -- Check if any children would exceed level 6
  for _, child_line in ipairs(child_lines) do
    local child_level = get_heading_level_at_line(child_line)
    if child_level and child_level >= 6 then
      vim.notify("Cannot demote: would push child headings beyond level 6", vim.log.levels.WARN, { title = "MarkdownEditor" })
      return false
    end
  end
  
  -- Demote the parent heading first
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local new_line = line:gsub("^(#+)", "%1#")
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
  
  -- Demote all child headings
  for _, child_line in ipairs(child_lines) do
    local child_line_content = vim.api.nvim_buf_get_lines(0, child_line - 1, child_line, false)[1]
    local new_child_line = child_line_content:gsub("^(#+)", "%1#")
    vim.api.nvim_buf_set_lines(0, child_line - 1, child_line, false, { new_child_line })
  end
  
  local child_count = #child_lines
  if child_count > 0 then
    vim.notify(string.format("Heading and %d children demoted to level %d", child_count, current_level + 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    vim.notify(string.format("Heading demoted to level %d", current_level + 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

---Promote a markdown heading and all its children (decrease level numbers)
---@return boolean success Whether the operation was successful
function M.promote_heading_with_children()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local current_level = M.get_heading_level()
  
  if not current_level then
    vim.notify("Cursor is not on a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  if current_level <= 1 then
    vim.notify("Cannot promote heading beyond level 1", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Find all child headings
  local child_lines = find_child_headings(line_num, current_level)
  
  -- Promote the parent heading first
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local new_line = line:gsub("^#+", function(match) 
    return match:sub(1, -2)
  end)
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
  
  -- Promote all child headings
  for _, child_line in ipairs(child_lines) do
    local child_line_content = vim.api.nvim_buf_get_lines(0, child_line - 1, child_line, false)[1]
    local new_child_line = child_line_content:gsub("^#+", function(match) 
      return match:sub(1, -2)
    end)
    vim.api.nvim_buf_set_lines(0, child_line - 1, child_line, false, { new_child_line })
  end
  
  local child_count = #child_lines
  if child_count > 0 then
    vim.notify(string.format("Heading and %d children promoted to level %d", child_count, current_level - 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    vim.notify(string.format("Heading promoted to level %d", current_level - 1), vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

---Insert a sibling heading at the same level as the nearest parent heading
---@return boolean success Whether the operation was successful
function M.insert_sibling_heading()
  local parent_line, parent_level = find_parent_heading()
  
  if not parent_line then
    -- No parent heading found, create a level 1 heading
    parent_level = 1
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Create the heading markers
  local heading_prefix = string.rep("#", parent_level) .. " "
  
  -- Check if cursor is on the parent heading line
  if parent_line and current_line == parent_line then
    -- Insert new heading below the parent
    local new_heading = heading_prefix
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { new_heading })
    -- Move cursor to the new line after the heading markers
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #heading_prefix })
    vim.notify(string.format("Created sibling heading at level %d below parent", parent_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    -- Insert heading markers at the beginning of the current line
    local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
    local new_line = heading_prefix .. line_content
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
    -- Adjust cursor position to account for the added heading markers
    local new_col = current_col + #heading_prefix
    vim.api.nvim_win_set_cursor(0, { current_line, new_col })
    
    if parent_line then
      vim.notify(string.format("Created sibling heading at level %d", parent_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
    else
      vim.notify("Created level 1 heading (no parent found)", vim.log.levels.INFO, { title = "MarkdownEditor" })
    end
  end
  
  return true
end

---Insert a child heading one level deeper than the nearest parent heading
---@return boolean success Whether the operation was successful
function M.insert_child_heading()
  local parent_line, parent_level = find_parent_heading()
  
  if not parent_line then
    -- No parent heading found, create a level 1 heading
    parent_level = 0 -- Will become level 1 after adding 1
  end
  
  local child_level = parent_level + 1
  
  if child_level > 6 then
    vim.notify("Cannot create child heading beyond level 6", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Create the heading markers
  local heading_prefix = string.rep("#", child_level) .. " "
  
  -- Check if cursor is on the parent heading line
  if parent_line and current_line == parent_line then
    -- Insert new heading below the parent
    local new_heading = heading_prefix
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { new_heading })
    -- Move cursor to the new line after the heading markers
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #heading_prefix })
    vim.notify(string.format("Created child heading at level %d below parent", child_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
  else
    -- Insert heading markers at the beginning of the current line
    local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
    local new_line = heading_prefix .. line_content
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, { new_line })
    -- Adjust cursor position to account for the added heading markers
    local new_col = current_col + #heading_prefix
    vim.api.nvim_win_set_cursor(0, { current_line, new_col })
    
    if parent_line then
      vim.notify(string.format("Created child heading at level %d", child_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
    else
      vim.notify("Created level 1 heading (no parent found)", vim.log.levels.INFO, { title = "MarkdownEditor" })
    end
  end
  
  return true
end

return M