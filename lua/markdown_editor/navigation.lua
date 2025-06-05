---@class MarkdownEditorNavigation
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

---Get the current heading that contains the cursor
---@return number|nil level The heading level (1-6) or nil if not found
---@return number|nil line_num The line number of the current heading
local function get_current_heading()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  
  -- First check if cursor is on a heading line
  local level = get_heading_level_at_line(current_line)
  if level then
    return level, current_line
  end
  
  -- Search backwards to find the heading this content belongs to
  for line_num = current_line - 1, 1, -1 do
    level = get_heading_level_at_line(line_num)
    if level then
      return level, line_num
    end
  end
  
  return nil, nil
end

---Navigate to the next heading at the same level
---@return boolean success Whether a next sibling heading was found
function M.next_sibling_heading()
  local current_level, current_line = get_current_heading()
  
  if not current_level or not current_line then
    vim.notify("Not in a heading section", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Search forward for next heading at same level
  for line_num = current_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level then
      if level == current_level then
        -- Found next sibling heading
        vim.api.nvim_win_set_cursor(0, { line_num, 0 })
        vim.notify(string.format("Moved to next level %d heading", current_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
        return true
      elseif level < current_level then
        -- Hit a parent heading, no more siblings
        break
      end
    end
  end
  
  vim.notify("No next sibling heading found", vim.log.levels.WARN, { title = "MarkdownEditor" })
  return false
end

---Navigate to the previous heading at the same level
---@return boolean success Whether a previous sibling heading was found
function M.previous_sibling_heading()
  local current_level, current_line = get_current_heading()
  
  if not current_level or not current_line then
    vim.notify("Not in a heading section", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Search backward for previous heading at same level
  for line_num = current_line - 1, 1, -1 do
    local level = get_heading_level_at_line(line_num)
    if level then
      if level == current_level then
        -- Found previous sibling heading
        vim.api.nvim_win_set_cursor(0, { line_num, 0 })
        vim.notify(string.format("Moved to previous level %d heading", current_level), vim.log.levels.INFO, { title = "MarkdownEditor" })
        return true
      elseif level < current_level then
        -- Hit a parent heading, no more siblings
        break
      end
    end
  end
  
  vim.notify("No previous sibling heading found", vim.log.levels.WARN, { title = "MarkdownEditor" })
  return false
end

---Navigate to the next heading at any level
---@return boolean success Whether a next heading was found
function M.next_heading()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Search forward for any heading
  for line_num = current_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level then
      vim.api.nvim_win_set_cursor(0, { line_num, 0 })
      vim.notify(string.format("Moved to next heading (level %d)", level), vim.log.levels.INFO, { title = "MarkdownEditor" })
      return true
    end
  end
  
  vim.notify("No next heading found", vim.log.levels.WARN, { title = "MarkdownEditor" })
  return false
end

---Navigate to the previous heading at any level
---@return boolean success Whether a previous heading was found
function M.previous_heading()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Search backward for any heading
  for line_num = current_line - 1, 1, -1 do
    local level = get_heading_level_at_line(line_num)
    if level then
      vim.api.nvim_win_set_cursor(0, { line_num, 0 })
      vim.notify(string.format("Moved to previous heading (level %d)", level), vim.log.levels.INFO, { title = "MarkdownEditor" })
      return true
    end
  end
  
  vim.notify("No previous heading found", vim.log.levels.WARN, { title = "MarkdownEditor" })
  return false
end

---Navigate to the parent heading (heading at a higher level that contains current position)
---@return boolean success Whether a parent heading was found
function M.parent_heading()
  local current_level, current_line = get_current_heading()
  
  if not current_level or not current_line then
    vim.notify("Not in a heading section", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Search backward for heading at higher level (lower number)
  for line_num = current_line - 1, 1, -1 do
    local level = get_heading_level_at_line(line_num)
    if level and level < current_level then
      vim.api.nvim_win_set_cursor(0, { line_num, 0 })
      vim.notify(string.format("Moved to parent heading (level %d)", level), vim.log.levels.INFO, { title = "MarkdownEditor" })
      return true
    end
  end
  
  vim.notify("No parent heading found", vim.log.levels.WARN, { title = "MarkdownEditor" })
  return false
end

return M