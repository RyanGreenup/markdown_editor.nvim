---@class MarkdownEditorReorder
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

---Find the next heading at the same level or higher
---@param start_line number The line to start searching from
---@param target_level number The level we're looking for
---@return number|nil end_line The line number where the section ends
local function find_section_end(start_line, target_level)
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  for line_num = start_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level and level <= target_level then
      return line_num - 1 -- Return the line before the next heading
    end
  end
  
  return total_lines -- End of file
end

---Find sibling headings (previous and next at same level)
---@param current_line number The line number of the current heading
---@param current_level number The level of the current heading
---@return number|nil prev_sibling Line number of previous sibling
---@return number|nil next_sibling Line number of next sibling
local function find_sibling_headings(current_line, current_level)
  local prev_sibling = nil
  local next_sibling = nil
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- Search backwards for previous sibling
  for line_num = current_line - 1, 1, -1 do
    local level = get_heading_level_at_line(line_num)
    if level then
      if level == current_level then
        prev_sibling = line_num
        break
      elseif level < current_level then
        -- Hit a parent heading, no more siblings
        break
      end
    end
  end
  
  -- Search forwards for next sibling
  for line_num = current_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level then
      if level == current_level then
        next_sibling = line_num
        break
      elseif level < current_level then
        -- Hit a parent heading, no more siblings
        break
      end
    end
  end
  
  return prev_sibling, next_sibling
end

---Extract the content of a heading section (heading + all content until next same/higher level heading)
---@param heading_line number The line number of the heading
---@param heading_level number The level of the heading
---@return string[] section_lines Array of lines including the heading and its content
local function extract_heading_section(heading_line, heading_level)
  local end_line = find_section_end(heading_line, heading_level)
  return vim.api.nvim_buf_get_lines(0, heading_line - 1, end_line, false)
end

---Move current heading up (swap with previous sibling)
---@return boolean success Whether the operation was successful
function M.move_heading_up()
  local current_level, current_line = get_current_heading()
  
  if not current_level or not current_line then
    vim.notify("Cursor is not on or under a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local prev_sibling, _ = find_sibling_headings(current_line, current_level)
  
  if not prev_sibling then
    vim.notify("No sibling heading found above to swap with", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Extract both sections
  local current_section = extract_heading_section(current_line, current_level)
  local prev_section = extract_heading_section(prev_sibling, current_level)
  
  -- Calculate line ranges
  local prev_end = find_section_end(prev_sibling, current_level)
  local current_end = find_section_end(current_line, current_level)
  
  -- Store cursor position relative to current section
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local relative_line = cursor_pos[1] - current_line
  local relative_col = cursor_pos[2]
  
  -- Replace the entire range with swapped sections
  local new_lines = {}
  vim.list_extend(new_lines, current_section)
  vim.list_extend(new_lines, prev_section)
  
  vim.api.nvim_buf_set_lines(0, prev_sibling - 1, current_end, false, new_lines)
  
  -- Update cursor position to follow the moved section
  local new_cursor_line = prev_sibling + relative_line
  vim.api.nvim_win_set_cursor(0, { new_cursor_line, relative_col })
  
  vim.notify("Heading moved up", vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Move current heading down (swap with next sibling)
---@return boolean success Whether the operation was successful
function M.move_heading_down()
  local current_level, current_line = get_current_heading()
  
  if not current_level or not current_line then
    vim.notify("Cursor is not on or under a markdown heading", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  local _, next_sibling = find_sibling_headings(current_line, current_level)
  
  if not next_sibling then
    vim.notify("No sibling heading found below to swap with", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Extract both sections
  local current_section = extract_heading_section(current_line, current_level)
  local next_section = extract_heading_section(next_sibling, current_level)
  
  -- Calculate line ranges
  local current_end = find_section_end(current_line, current_level)
  local next_end = find_section_end(next_sibling, current_level)
  
  -- Store cursor position relative to current section
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local relative_line = cursor_pos[1] - current_line
  local relative_col = cursor_pos[2]
  
  -- Replace the entire range with swapped sections
  local new_lines = {}
  vim.list_extend(new_lines, next_section)
  vim.list_extend(new_lines, current_section)
  
  vim.api.nvim_buf_set_lines(0, current_line - 1, next_end, false, new_lines)
  
  -- Update cursor position to follow the moved section
  local new_cursor_line = current_line + #next_section + relative_line
  vim.api.nvim_win_set_cursor(0, { new_cursor_line, relative_col })
  
  vim.notify("Heading moved down", vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

return M