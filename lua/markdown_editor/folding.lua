---@class MarkdownEditorFolding
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

---Get all headings in the buffer with their line numbers and levels
---@return table headings Array of {line = number, level = number}
local function get_all_headings()
  local headings = {}
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  for line_num = 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level then
      table.insert(headings, { line = line_num, level = level })
    end
  end
  
  return headings
end

---Find the end line of a heading section
---@param start_line number The line number of the heading
---@param heading_level number The level of the heading
---@return number end_line The last line of the section
local function find_section_end(start_line, heading_level)
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  for line_num = start_line + 1, total_lines do
    local level = get_heading_level_at_line(line_num)
    if level and level <= heading_level then
      return line_num - 1
    end
  end
  
  return total_lines
end

---Get the current fold state of the buffer
---@return string state Current fold state: "all_open", "level_1", "level_2", etc., or "all_closed"
local function get_current_fold_state()
  local headings = get_all_headings()
  if #headings == 0 then
    return "all_open"
  end
  
  local level_folded = {}
  local any_open = false
  
  -- Check each heading to see if it's folded
  for _, heading in ipairs(headings) do
    local fold_closed = vim.fn.foldclosed(heading.line) ~= -1
    if fold_closed then
      level_folded[heading.level] = true
    else
      any_open = true
    end
  end
  
  -- Determine the current state
  if not any_open then
    return "all_closed"
  end
  
  -- Check if specific levels are consistently folded
  for level = 1, 6 do
    local all_level_folded = true
    local has_level = false
    
    for _, heading in ipairs(headings) do
      if heading.level == level then
        has_level = true
        if vim.fn.foldclosed(heading.line) == -1 then
          all_level_folded = false
          break
        end
      end
    end
    
    if has_level and all_level_folded then
      return "level_" .. level
    end
  end
  
  return "all_open"
end

---Set up markdown folding based on headings
local function setup_markdown_folding()
  -- Enable folding
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.require('markdown_editor.folding').fold_expr()"
  vim.opt_local.foldtext = "v:lua.require('markdown_editor.folding').fold_text()"
  vim.opt_local.fillchars:append("fold: ")
  vim.opt_local.foldlevelstart = 99  -- Start with all folds open
end

---Fold expression function for markdown headings
---@param lnum number|nil Line number (optional, defaults to v:lnum)
---@return string fold_level The fold level for the line
function M.fold_expr(lnum)
  lnum = lnum or vim.v.lnum
  local level = get_heading_level_at_line(lnum)
  
  if level then
    return ">" .. level
  else
    return "="
  end
end

---Custom fold text function
---@return string fold_text The text to display for the fold
function M.fold_text()
  local line = vim.fn.getline(vim.v.foldstart)
  local lines_count = vim.v.foldend - vim.v.foldstart + 1
  local suffix = string.format(" (%d lines)", lines_count)
  
  -- Remove excess whitespace and add suffix
  local cleaned_line = line:gsub("^%s*", ""):gsub("%s*$", "")
  return cleaned_line .. suffix
end

---Fold all headings at a specific level and below
---@param max_level number Maximum level to keep open (1-6)
local function fold_to_level(max_level)
  local headings = get_all_headings()
  
  -- First, open all folds
  vim.cmd("normal! zR")
  
  -- Then close folds for headings at level > max_level
  for _, heading in ipairs(headings) do
    if heading.level > max_level then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      vim.cmd("normal! zc")
    end
  end
end

---Close all folds
local function close_all_folds()
  vim.cmd("normal! zM")
end

---Open all folds
local function open_all_folds()
  vim.cmd("normal! zR")
end

---Cycle through fold states like org-mode
---@return boolean success Whether the operation was successful
function M.cycle_fold()
  -- Set up folding if not already configured
  if vim.opt_local.foldmethod:get() ~= "expr" then
    setup_markdown_folding()
    -- Give time for fold expression to be evaluated
    vim.schedule(function()
      M.cycle_fold()
    end)
    return true
  end
  
  local current_state = get_current_fold_state()
  
  -- Cycle through states: all_open -> level_1 -> level_2 -> ... -> all_closed -> all_open
  if current_state == "all_open" then
    fold_to_level(1)
    vim.notify("Folded to level 1", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_1" then
    fold_to_level(2)
    vim.notify("Folded to level 2", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_2" then
    fold_to_level(3)
    vim.notify("Folded to level 3", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_3" then
    fold_to_level(4)
    vim.notify("Folded to level 4", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_4" then
    fold_to_level(5)
    vim.notify("Folded to level 5", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_5" then
    fold_to_level(6)
    vim.notify("Folded to level 6", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "level_6" then
    close_all_folds()
    vim.notify("All headings folded", vim.log.levels.INFO, { title = "MarkdownEditor" })
  else  -- all_closed or any other state
    open_all_folds()
    vim.notify("All folds opened", vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

---Initialize folding for the current buffer
function M.setup_buffer_folding()
  setup_markdown_folding()
end

return M