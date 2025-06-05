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

---Get the current fold state of the buffer (3-state system)
---@return string state Current fold state: "overview", "contents", or "show_all"
local function get_current_fold_state()
  local headings = get_all_headings()
  if #headings == 0 then
    return "show_all"
  end
  
  local level1_folded = true
  local all_headings_folded = true
  local any_folds = false
  
  -- Check the state of level 1 headings and all headings
  for _, heading in ipairs(headings) do
    local fold_closed = vim.fn.foldclosed(heading.line) ~= -1
    
    if fold_closed then
      any_folds = true
      if heading.level > 1 then
        -- If any non-level-1 heading is folded, we might be in contents state
      end
    else
      all_headings_folded = false
      if heading.level == 1 then
        level1_folded = false
      end
    end
  end
  
  -- Determine state based on fold patterns
  if not any_folds then
    return "show_all"
  end
  
  -- Check if we're in overview state (only level 1 headings visible)
  if level1_folded then
    -- Check if level 1 headings have their content folded
    local level1_content_folded = false
    for _, heading in ipairs(headings) do
      if heading.level == 1 then
        local fold_closed = vim.fn.foldclosed(heading.line) ~= -1
        if fold_closed then
          level1_content_folded = true
          break
        end
      end
    end
    
    if level1_content_folded then
      return "overview"
    end
  end
  
  -- Check if we're in contents state (all headings visible, content folded)
  local content_folded = false
  for _, heading in ipairs(headings) do
    -- Check if there's content after this heading that should be folded
    local end_line = find_section_end(heading.line, heading.level)
    if end_line > heading.line then
      -- There's content, check if it's folded
      local fold_closed = vim.fn.foldclosed(heading.line) ~= -1
      if fold_closed then
        content_folded = true
        break
      end
    end
  end
  
  if content_folded and not all_headings_folded then
    return "contents"
  end
  
  return "show_all"
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

---Set to overview state: only top-level headings visible
local function set_overview_state()
  local headings = get_all_headings()
  
  -- First, open all folds
  vim.cmd("normal! zR")
  
  -- Find level 1 headings and fold everything under them
  for _, heading in ipairs(headings) do
    if heading.level == 1 then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      vim.cmd("normal! zc")
    end
  end
end

---Set to contents state: all headings visible, content folded
local function set_contents_state()
  local headings = get_all_headings()
  
  -- First, open all folds
  vim.cmd("normal! zR")
  
  -- For each heading, if it has content (non-heading lines), fold just the content
  for _, heading in ipairs(headings) do
    local end_line = find_section_end(heading.line, heading.level)
    
    -- Check if there's content (non-heading lines) in this section
    local has_content = false
    for line_num = heading.line + 1, end_line do
      if not get_heading_level_at_line(line_num) then
        has_content = true
        break
      end
    end
    
    -- If there's content, create a fold that includes the heading and its content
    if has_content then
      vim.api.nvim_win_set_cursor(0, { heading.line, 0 })
      vim.cmd("normal! zc")
    end
  end
end

---Set to show all state: everything expanded
local function set_show_all_state()
  vim.cmd("normal! zR")
end

---Cycle through fold states like org-mode (3-state system)
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
  
  -- Cycle through 3 states: show_all -> overview -> contents -> show_all
  if current_state == "show_all" then
    set_overview_state()
    vim.notify("Overview: Only top-level headings visible", vim.log.levels.INFO, { title = "MarkdownEditor" })
  elseif current_state == "overview" then
    set_contents_state()
    vim.notify("Contents: All headings visible, content folded", vim.log.levels.INFO, { title = "MarkdownEditor" })
  else  -- contents or any other state
    set_show_all_state()
    vim.notify("Show all: Everything expanded", vim.log.levels.INFO, { title = "MarkdownEditor" })
  end
  
  return true
end

---Initialize folding for the current buffer
function M.setup_buffer_folding()
  setup_markdown_folding()
end

return M