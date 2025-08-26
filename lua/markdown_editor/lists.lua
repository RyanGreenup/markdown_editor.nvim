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

---Check if cursor is on a list item or content belonging to a list item
---@return string|nil marker The list marker (-, *, +) or nil if not in a list context
---@return number|nil indent The indentation level of the parent list item
---@return boolean is_content Whether we're on list content (not the list item itself)
function M.get_list_item_info()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line_num - 1, current_line_num, false)[1]
  
  if not line_content then
    return nil, nil, false
  end
  
  -- First check if current line is a list item
  local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
  
  if marker then
    local indent_level = #indent_str
    return marker, indent_level, false
  end
  
  -- If not a list item, check if we're on content that belongs to a list item
  local current_indent = #(line_content:match("^(%s*)") or "")
  
  -- Only consider it list content if the line has some indentation
  if current_indent > 0 then
    -- Search backwards to find the parent list item
    for line_num = current_line_num - 1, 1, -1 do
      local search_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
      if search_content then
        local search_indent_str, search_marker = search_content:match("^(%s*)([-*+])%s")
        
        if search_marker then
          local search_indent = #search_indent_str
          
          -- Check if current line is indented relative to this list item
          -- It should be indented more than the list item to be considered its content
          if current_indent > search_indent then
            return search_marker, search_indent, true
          else
            -- Found a list item at same or greater indent level, not our parent
            break
          end
        else
          -- Check if this line has less or equal indentation (end of list content)
          local search_line_indent = #(search_content:match("^(%s*)") or "")
          if search_line_indent <= current_indent and search_content:match("%S") then
            -- Found a line with less indentation that has content, we're not in list anymore
            break
          end
        end
      end
    end
  end
  
  return nil, nil, false
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Create the list item prefix
  local indent_str = string.rep(" ", indent_level)
  local list_prefix = indent_str .. marker .. " "
  
  if is_content then
    -- We're on list content, always insert new list item below current line
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #list_prefix })
    return true
  end
  
  -- We're on the actual list item line
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
  end
  
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local current_col = vim.api.nvim_win_get_cursor(0)[2]
  
  -- Increase indentation by configured amount
  local indent_size = get_indent_size()
  local child_indent = indent_level + indent_size
  local indent_str = string.rep(" ", child_indent)
  local list_prefix = indent_str .. marker .. " "
  
  if is_content then
    -- We're on list content, always insert new child list item below current line
    vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { list_prefix })
    vim.api.nvim_win_set_cursor(0, { current_line + 1, #list_prefix })
    return true
  end
  
  -- We're on the actual list item line
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
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
  local marker, indent_level, is_content = M.get_list_item_info()
  
  if not marker then
    return false -- Not in a list context
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

---Setup auto-indentation for lists in the current buffer
---This function is called when entering a markdown buffer
function M.setup_auto_indent()
  -- Check if auto-indent is enabled
  if not config.get("auto_indent_lists") then
    return
  end
  
  -- Create buffer-local autocommand for Enter key in insert mode
  vim.api.nvim_create_autocmd("InsertCharPre", {
    buffer = 0,
    callback = function()
      -- Only process Enter key
      if vim.v.char ~= "\n" then
        return
      end
      
      local current_line = vim.api.nvim_win_get_cursor(0)[1]
      local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
      
      if not line_content then
        return
      end
      
      -- Check if we're on a list item line
      local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
      
      if marker then
        -- We're on a list item, prepare auto-indentation
        local indent_level = #indent_str
        local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
        
        -- If the list item is empty, we might want to end the list
        if not content_after_marker or content_after_marker == "" then
          -- Empty list item - don't auto-indent (user might be ending the list)
          return
        end
        
        -- Calculate the indent for content under the list item
        local indent_size = get_indent_size()
        local content_indent = indent_level + indent_size
        local indent_for_content = string.rep(" ", content_indent)
        
        -- Schedule the indentation to be inserted after the newline
        vim.schedule(function()
          local new_line = vim.api.nvim_win_get_cursor(0)[1]
          local new_line_content = vim.api.nvim_buf_get_lines(0, new_line - 1, new_line, false)[1]
          
          -- Only add indent if the new line is empty
          if new_line_content == "" then
            vim.api.nvim_buf_set_lines(0, new_line - 1, new_line, false, { indent_for_content })
            -- Move cursor to end of indent
            vim.api.nvim_win_set_cursor(0, { new_line, content_indent })
          end
        end)
      else
        -- Check if we're on an indented line under a list item
        local line_indent = #(line_content:match("^(%s*)") or "")
        
        if line_indent > 0 then
          -- We're on an indented line, maintain the same indentation
          local indent_str_only = string.rep(" ", line_indent)
          
          vim.schedule(function()
            local new_line = vim.api.nvim_win_get_cursor(0)[1]
            local new_line_content = vim.api.nvim_buf_get_lines(0, new_line - 1, new_line, false)[1]
            
            -- Only add indent if the new line is empty
            if new_line_content == "" then
              vim.api.nvim_buf_set_lines(0, new_line - 1, new_line, false, { indent_str_only })
              -- Move cursor to end of indent
              vim.api.nvim_win_set_cursor(0, { new_line, line_indent })
            end
          end)
        end
      end
    end,
  })
  
  -- Alternative approach using 'o' mapping for normal mode
  local function create_indented_line()
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]
    
    if not line_content then
      return "o"
    end
    
    -- Check if we're on a list item line
    local indent_str, marker = line_content:match("^(%s*)([-*+])%s")
    
    if marker then
      local indent_level = #indent_str
      local content_after_marker = line_content:match("^%s*[-*+]%s*(.*)")
      
      if content_after_marker and content_after_marker ~= "" then
        -- Calculate the indent for content under the list item
        local indent_size = get_indent_size()
        local content_indent = indent_level + indent_size
        local indent_for_content = string.rep(" ", content_indent)
        return "o" .. indent_for_content
      end
    else
      -- Check if we're on an indented line under a list item
      local line_indent = #(line_content:match("^(%s*)") or "")
      
      if line_indent > 0 then
        local indent_str_only = string.rep(" ", line_indent)
        return "o" .. indent_str_only
      end
    end
    
    return "o"
  end
  
  -- Map 'o' in normal mode to add proper indentation
  vim.keymap.set("n", "o", create_indented_line, { 
    buffer = 0, 
    expr = true,
    desc = "Create new line with proper list indentation" 
  })
  
  -- Map 'O' for creating line above (less common in lists, but included for completeness)
  vim.keymap.set("n", "O", "O", { 
    buffer = 0, 
    desc = "Create new line above" 
  })
end

return M