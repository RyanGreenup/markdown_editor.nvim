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

---Get user input for link components
---@param default_desc string|nil Default description
---@param default_target string|nil Default target
---@return string|nil description User entered description
---@return string|nil target User entered target
local function get_link_input(default_desc, default_target)
  default_desc = default_desc or ""
  default_target = default_target or ""
  
  -- Get description
  local description = vim.fn.input("Link description: ", default_desc)
  if description == "" then
    return nil, nil
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

---Smart link function that detects context and calls appropriate function
---@return boolean success Whether the operation was successful
function M.smart_link()
  local is_on_link, link_info = detect_link_at_cursor()
  
  if is_on_link and link_info then
    return M.edit_link(link_info)
  else
    return M.create_link()
  end
end

return M