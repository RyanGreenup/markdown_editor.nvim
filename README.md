# Markdown Editor

This plugin provides tree sitter based keybindings to edit markdown documents. Motivated by a love of org-mode but a need for markdown.

## Quick start (Lazy.nvim)



| Keybinding | Function | Description |
|------------|----------|-------------|
| `<C-CR>` | `insert_child_heading()` | Create a new child heading (one level deeper) |
| `<M-CR>` | `insert_sibling_heading()` | Create a new sibling heading (same level) |
| `<M-l>` | `demote_heading_with_children()` | Demote heading and all its children |
| `<C-l>` | `demote_heading()` | Demote only the current heading |
| `<M-h>` | `promote_heading_with_children()` | Promote heading and all its children |
| `<C-h>` | `promote_heading()` | Promote only the current heading |
| `<M-Up>` | `move_heading_up()` | Swap heading with sibling above |
| `<M-Down>` | `move_heading_down()` | Swap heading with sibling below |
| `<C-c><C-l>` | `smart_link()` | Create or edit markdown link |



```lua
{
  "ryangreenup/markdown_editor.nvim", -- Replace with actual plugin path
  config = function()
    require("markdown_editor").setup({
      -- Your plugin configuration here
    })

    -- Create autocmd for markdown keybindings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "rmd" },
      callback = function()
        local opts = { buffer = true, silent = true }

        -- Heading Creation
        vim.keymap.set("n", "<C-CR>", function()
          require("markdown_editor.headings").insert_child_heading()
        end, vim.tbl_extend("force", opts, { desc = "Create child heading" }))

        vim.keymap.set("n", "<M-CR>", function()
          require("markdown_editor.headings").insert_sibling_heading()
        end, vim.tbl_extend("force", opts, { desc = "Create sibling heading" }))

        -- Heading Promotion/Demotion with Children
        vim.keymap.set("n", "<M-l>", function()
          require("markdown_editor.headings").demote_heading_with_children()
        end, vim.tbl_extend("force", opts, { desc = "Demote heading with children" }))

        vim.keymap.set("n", "<M-h>", function()
          require("markdown_editor.headings").promote_heading_with_children()
        end, vim.tbl_extend("force", opts, { desc = "Promote heading with children" }))

        -- Single Heading Promotion/Demotion
        vim.keymap.set("n", "<C-l>", function()
          require("markdown_editor.headings").demote_heading()
        end, vim.tbl_extend("force", opts, { desc = "Demote current heading only" }))

        vim.keymap.set("n", "<C-h>", function()
          require("markdown_editor.headings").promote_heading()
        end, vim.tbl_extend("force", opts, { desc = "Promote current heading only" }))

        -- Heading Reordering
        vim.keymap.set("n", "<M-Up>", function()
          require("markdown_editor.reorder").move_heading_up()
        end, vim.tbl_extend("force", opts, { desc = "Move heading up" }))

        vim.keymap.set("n", "<M-Down>", function()
          require("markdown_editor.reorder").move_heading_down()
        end, vim.tbl_extend("force", opts, { desc = "Move heading down" }))
        
        -- Link Management
        vim.keymap.set("n", "<C-c><C-l>", function()
          require("markdown_editor.links").smart_link()
        end, vim.tbl_extend("force", opts, { desc = "Create or edit markdown link" }))
        
        vim.keymap.set("v", "<C-c><C-l>", function()
          require("markdown_editor.links").smart_link(true)
        end, vim.tbl_extend("force", opts, { desc = "Create link from selection" }))
      end,
    })
  end,
}
```

## Usage Examples

### Link Management

The `<C-c><C-l>` keybinding provides smart link functionality:

**Normal Mode:**
- On existing link: Edit the link (pre-fills current values)
- Not on link: Create new link at cursor position

**Visual Mode:**
- Select text and press `<C-c><C-l>`: Creates a link using the selected text as the description

**Examples:**

```markdown
# Normal mode - creating new link
Some text| <- cursor here, press <C-c><C-l>
# Prompts for description and target
Some text[My Link](https://example.com)| <- result

# Normal mode - editing existing link
Check out [old text](old-url)| <- cursor on link, press <C-c><C-l>
# Prompts with current values pre-filled
Check out [new text](new-url)| <- result after editing

# Visual mode - link from selection
Select this text and press <C-c><C-l>
# Only prompts for target (selected text becomes description)
[Select this text](https://example.com) <- result
```


