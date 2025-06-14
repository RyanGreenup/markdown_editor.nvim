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
| `<C-c><C-n>` | `next_sibling_heading()` | Navigate to next sibling heading |
| `<C-c><C-p>` | `previous_sibling_heading()` | Navigate to previous sibling heading |
| `<C-c><C-f>` | `next_heading()` | Navigate to next heading (any level) |
| `<C-c><C-b>` | `previous_heading()` | Navigate to previous heading (any level) |
| `<C-c><C-u>` | `parent_heading()` | Navigate to parent heading |
| `<S-Tab>` | `cycle_fold()` | Cycle fold state (org-mode style) |



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
        
        -- Navigation
        vim.keymap.set("n", "<C-c><C-n>", function()
          require("markdown_editor.navigation").next_sibling_heading()
        end, vim.tbl_extend("force", opts, { desc = "Next sibling heading" }))
        
        vim.keymap.set("n", "<C-c><C-p>", function()
          require("markdown_editor.navigation").previous_sibling_heading()
        end, vim.tbl_extend("force", opts, { desc = "Previous sibling heading" }))
        
        vim.keymap.set("n", "<C-c><C-f>", function()
          require("markdown_editor.navigation").next_heading()
        end, vim.tbl_extend("force", opts, { desc = "Next heading (any level)" }))
        
        vim.keymap.set("n", "<C-c><C-b>", function()
          require("markdown_editor.navigation").previous_heading()
        end, vim.tbl_extend("force", opts, { desc = "Previous heading (any level)" }))
        
        vim.keymap.set("n", "<C-c><C-u>", function()
          require("markdown_editor.navigation").parent_heading()
        end, vim.tbl_extend("force", opts, { desc = "Parent heading" }))
        
        -- Folding
        vim.keymap.set("n", "<S-Tab>", function()
          require("markdown_editor.folding").cycle_fold()
        end, vim.tbl_extend("force", opts, { desc = "Cycle fold state" }))
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

### Navigation

The plugin provides several navigation functions to move between headings:

**Sibling Navigation** (`<C-c><C-n>` / `<C-c><C-p>`):
- Moves between headings at the same level
- Stops at parent boundaries (won't cross into different sections)

**Any Level Navigation** (`<C-c><C-f>` / `<C-c><C-b>`):
- Moves to next/previous heading regardless of level
- Useful for quick navigation through the entire document

**Parent Navigation** (`<C-c><C-u>`):
- Moves to the parent heading (higher level that contains current position)
- Useful for jumping up in the document hierarchy

**Example Navigation:**

```markdown
# Top Level          <- parent_heading() lands here from anywhere below
## Section A         <- previous_sibling_heading() from Section B
### Subsection A1    <- previous_heading() from anywhere below
### Subsection A2    
## Section B         <- current position, next_sibling_heading() goes to Section C
### Subsection B1    
## Section C         <- next_sibling_heading() from Section B
```

### Folding

The plugin provides org-mode style folding that cycles through different fold states:

**Fold Cycling** (`<S-Tab>`):
- Progressively folds headings from level 1 to 6
- Cycles through: All Open → Level 1 → Level 2 → ... → Level 6 → All Closed → All Open

**Folding Behavior:**
- Only headings are foldable (content under headings gets folded)
- Maintains cursor position during fold cycling
- Automatically sets up folding when opening markdown files
- Uses treesitter for accurate heading detection

**Fold States:**
1. **All Open**: All content visible
2. **Level 1**: Only level 1 headings visible, everything else folded
3. **Level 2**: Level 1-2 headings visible, level 3+ folded
4. **Level 3**: Level 1-3 headings visible, level 4+ folded
5. **Level 4**: Level 1-4 headings visible, level 5+ folded
6. **Level 5**: Level 1-5 headings visible, level 6 folded
7. **Level 6**: All headings visible, only content folded
8. **All Closed**: Everything folded

**Example:**

```markdown
# Document               <- Always visible
## Section A             <- Folded at Level 1
### Subsection A1        <- Folded at Level 2
Content here...          <- Folded with parent heading
### Subsection A2        <- Folded at Level 2
## Section B             <- Folded at Level 1
### Subsection B1        <- Folded at Level 2
```


