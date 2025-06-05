---@class MarkdownEditorLinks
local M = {}

---Get the treesitter node at cursor position
---@return TSNode|nil
local function get_node_at_cursor()
  local ts_utils = require('nvim-treesitter.ts_utils')
  return ts_utils.get_node_at_cursor(0)
end

---Check if cursor is on a markdown link using treesitter
---@return boolean is_on_link Whether cursor is on a link
---@return table|nil link_info Link information if on a link
local function detect_link_at_cursor()
  local node = get_node_at_cursor()
  if not node then
    return false, nil
  end
  
  -- Walk up the tree to find a link node
  local current = node
  while current do
    local node_type = current:type()
    
    -- Check for inline link node
    if node_type == "inline_link" then
      local start_row, start_col, end_row, end_col = current:range()
      local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
      
      if #lines > 0 then
        local link_text = table.concat(lines, "\n"):sub(start_col + 1, end_col)
        
        -- Parse the link text to extract description and target
        local desc, target = link_text:match("%[(.-)%]%((.-)%)")
        if desc and target then
          return true, {
            description = desc,
            target = target,
            start_row = start_row,
            start_col = start_col,
            end_row = end_row,
            end_col = end_col,
            full_text = link_text
          }
        end
      end
    end
    
    current = current:parent()
  end
  
  return false, nil
end

---Get the current visual selection
---@return string|nil selection_text The selected text
---@return table|nil selection_info Selection position information
local function get_visual_selection()
  -- Get the start and end positions of the visual selection
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- Extract line and column numbers (1-indexed)
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  
  -- Get the selected lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines == 0 then
    return nil, nil
  end
  
  local selection_text
  if #lines == 1 then
    -- Single line selection
    selection_text = lines[1]:sub(start_col, end_col)
  else
    -- Multi-line selection
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
    selection_text = table.concat(lines, "\n")
  end
  
  return selection_text, {
    start_line = start_line,
    start_col = start_col,
    end_line = end_line,
    end_col = end_col
  }
end

---Get user input for link components
---@param default_desc string|nil Default description
---@param default_target string|nil Default target
---@param skip_description boolean|nil Whether to skip description input
---@return string|nil description User entered description
---@return string|nil target User entered target
local function get_link_input(default_desc, default_target, skip_description)
  default_desc = default_desc or ""
  default_target = default_target or ""
  
  local description = default_desc
  
  -- Get description (unless we're skipping it because we have selected text)
  if not skip_description then
    description = vim.fn.input("Link description: ", default_desc)
    if description == "" then
      return nil, nil
    end
  end
  
  -- Get target
  local target = vim.fn.input("Link target: ", default_target)
  if target == "" then
    return nil, nil
  end
  
  return description, target
end

---Create a new markdown link at cursor position
---@return boolean success Whether the operation was successful
function M.create_link()
  local description, target = get_link_input()
  
  if not description or not target then
    vim.notify("Link creation cancelled", vim.log.levels.INFO, { title = "MarkdownEditor" })
    return false
  end
  
  local link_text = string.format("[%s](%s)", description, target)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1]
  local col_num = cursor_pos[2]
  
  -- Get current line
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  
  -- Insert link at cursor position
  local new_line = line:sub(1, col_num) .. link_text .. line:sub(col_num + 1)
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })
  
  -- Position cursor after the link
  local new_col = col_num + #link_text
  vim.api.nvim_win_set_cursor(0, { line_num, new_col })
  
  vim.notify(string.format("Created link: %s", link_text), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Edit an existing markdown link at cursor position
---@param link_info table Link information from detection
---@return boolean success Whether the operation was successful
function M.edit_link(link_info)
  local description, target = get_link_input(link_info.description, link_info.target)
  
  if not description or not target then
    vim.notify("Link editing cancelled", vim.log.levels.INFO, { title = "MarkdownEditor" })
    return false
  end
  
  local new_link_text = string.format("[%s](%s)", description, target)
  
  -- Replace the link in the buffer
  local start_row, start_col = link_info.start_row, link_info.start_col
  local end_row, end_col = link_info.end_row, link_info.end_col
  
  -- Get the lines containing the link
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  
  if #lines == 1 then
    -- Single line replacement
    local line = lines[1]
    local new_line = line:sub(1, start_col) .. new_link_text .. line:sub(end_col + 1)
    vim.api.nvim_buf_set_lines(0, start_row, start_row + 1, false, { new_line })
  else
    -- Multi-line replacement (less common for links, but handle it)
    local first_line = lines[1]:sub(1, start_col) .. new_link_text
    local last_line = lines[#lines]:sub(end_col + 1)
    local new_line = first_line .. last_line
    vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, { new_line })
  end
  
  -- Position cursor after the edited link
  local new_col = start_col + #new_link_text
  vim.api.nvim_win_set_cursor(0, { start_row + 1, new_col })
  
  vim.notify(string.format("Updated link: %s", new_link_text), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Create a link from visual selection
---@return boolean success Whether the operation was successful
function M.create_link_from_selection()
  local selection_text, selection_info = get_visual_selection()
  
  if not selection_text or not selection_info then
    vim.notify("No visual selection found", vim.log.levels.WARN, { title = "MarkdownEditor" })
    return false
  end
  
  -- Use selected text as description, only prompt for target
  local description, target = get_link_input(selection_text, "", true)
  
  if not description or not target then
    vim.notify("Link creation cancelled", vim.log.levels.INFO, { title = "MarkdownEditor" })
    return false
  end
  
  local link_text = string.format("[%s](%s)", description, target)
  
  -- Replace the selected text with the link
  local start_line, start_col = selection_info.start_line, selection_info.start_col
  local end_line, end_col = selection_info.end_line, selection_info.end_col
  
  -- Get the lines containing the selection
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines == 1 then
    -- Single line replacement
    local line = lines[1]
    local new_line = line:sub(1, start_col - 1) .. link_text .. line:sub(end_col + 1)
    vim.api.nvim_buf_set_lines(0, start_line - 1, start_line, false, { new_line })
  else
    -- Multi-line replacement
    local first_part = lines[1]:sub(1, start_col - 1)
    local last_part = lines[#lines]:sub(end_col + 1)
    local new_line = first_part .. link_text .. last_part
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, { new_line })
  end
  
  -- Position cursor after the link
  local new_col = start_col - 1 + #link_text
  vim.api.nvim_win_set_cursor(0, { start_line, new_col })
  
  vim.notify(string.format("Created link from selection: %s", link_text), vim.log.levels.INFO, { title = "MarkdownEditor" })
  return true
end

---Smart link function that detects context and calls appropriate function
---@param visual_mode boolean|nil Whether called from visual mode
---@return boolean success Whether the operation was successful
function M.smart_link(visual_mode)
  -- Handle visual selection mode
  if visual_mode then
    return M.create_link_from_selection()
  end
  
  -- Normal mode behavior
  local is_on_link, link_info = detect_link_at_cursor()
  
  if is_on_link and link_info then
    return M.edit_link(link_info)
  else
    return M.create_link()
  end
end

return M