# 📝 Scratch.nvim

Scratch.nvim is a powerful scratch buffer plugin for Neovim that allows you to quickly write, execute, and experiment with code snippets. With a focus on interactivity and real-time feedback, it's the perfect companion for debugging, learning, and testing code snippets in various languages.

![Scratch.nvim Demo](https://github.com/yourusername/scratch.nvim/assets/demo.gif)

## ✨ Features

- **Interactive Code Execution**: Execute code directly within Neovim
- **Line-by-Line Results**: See results for each line right at the end of the line (`code --> result`)
- **Multiple Language Support**: Works with Lua, Python, JavaScript, and many more
- **Real-Time Execution**: Instantly see results as you exit insert mode
- **Debug Mode**: Step through code execution one line at a time
- **Visual Results**: Clean, attractive visualization of execution results
- **FZF Integration**: Quickly browse and manage scratch files
- **Named Scratch Files**: Save and organize your useful snippets
- **Window Position Memory**: Scratch windows remember their position when toggled
- **Enhanced UI**: Beautiful non-minimal window style with syntax highlighting and line numbers

## 🚀 Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/scratch.nvim',
  config = function()
    require('scratch').setup({
      -- Your configuration here
    })
  end
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yourusername/scratch.nvim',
  config = function()
    require('scratch').setup({
      -- Your configuration here
    })
  end
}
```

## ⚙️ Configuration

Here's a complete configuration with all default options:

```lua
require('scratch').setup({
  name = "Scratch",  -- Default name for scratch buffers
  
  -- Filetype determination
  ft = function()
    if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
      return vim.bo.filetype
    end
    return "markdown"
  end,
  
  root = vim.fn.stdpath("data") .. "/scratch",  -- Directory for scratch files
  autowrite = true,                            -- Auto-save when buffer is hidden
  save_on_toggle = true,                       -- Save when toggling the scratch buffer
  show_results_on_execute = true,              -- Show results after execution
  real_time_execution = true,                  -- Execute code when leaving insert mode
  line_by_line_results = true,                 -- Show results for each line
  debug_mode = false,                          -- Enable debug mode by default
  result_indicator = "→",                      -- Character for result indicator
  
  -- File naming configuration
  filekey = {
    cwd = true,     -- Include current working directory in filename
    branch = true,  -- Include git branch in filename
    count = true,   -- Include count in filename (for <count>F5)
  },
  
  -- Window appearance
  win = {
    width = 100,
    height = 30,
    minimal = false,  -- Non-minimal style with line numbers and signs
    wo = {
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual",
      cursorline = true,
      signcolumn = "yes",
      foldcolumn = "0",
      number = true,
      relativenumber = false,
      wrap = false,
    },
    border = "rounded",
    title_pos = "center",
    footer_pos = "center",
  },
  
  -- UI configuration
  ui = {
    float_border = "rounded",
    float_shadow = true,
    float_title_style = "center",
    result_inline = true,
    result_virt_lines = false,  -- Show results at EOL rather than below each line
    result_padding = 2,         -- Padding between code and result
    themed = true,              -- Use your colorscheme for styling
    hl_result = "Special",      -- Highlight group for results
    hl_error = "DiagnosticError", -- Highlight group for errors
  },
  
  -- Keymappings
  keymaps = {
    toggle = "<F5>",
    execute = "<CR>",
    hide = "<Esc>",
    toggle_results = "<leader>sr",
    save = "<leader>ss",
    toggle_real_time = "<leader>st",
    toggle_debug = "<leader>sd",
    clear_results = "<leader>sc",
    clear_scratch = "<leader>sx",
  },
  
  -- Language interpreters
  interpreters = {
    python = "python",
    lua = "neovim",  -- Special handler for Lua with Neovim API access
    javascript = "node",
    typescript = "ts-node",
    ruby = "ruby",
    bash = "bash",
    sh = "sh",
    zsh = "zsh",
    r = "Rscript",
    julia = "julia",
    perl = "perl",
    php = "php",
    -- Add more as needed
  },
})
```

## 🔍 Usage

### Basic Commands

- `:ScratchToggle` - Toggle the scratch buffer for the current filetype
- `:ScratchOpen [filetype]` - Open a scratch buffer with optional filetype
- `:ScratchSelect` - Select from existing scratch buffers
- `:ScratchSelectNamed` - Select from named scratch files
- `:ScratchClear` - Clear all unnamed scratch files
- `:ScratchDebug` - Toggle debug mode

### Default Keymaps

| Keymap           | Action                                    |
|------------------|-------------------------------------------|
| `<F5>`           | Toggle scratch buffer                     |
| `<CR>`           | Execute code (normal or visual mode)      |
| `<Esc>`          | Hide scratch buffer                       |
| `<leader>sr`     | Toggle result display                     |
| `<leader>ss`     | Save scratch with a name                  |
| `<leader>st`     | Toggle real-time execution                |
| `<leader>sd`     | Toggle debug mode                         |
| `<leader>sc`     | Clear execution results                   |
| `<leader>sx`     | Clear all unnamed scratch files           |

### Working with Results

Results are shown at the end of each line in the format: `code → result`. This provides clean, immediate feedback on each line of code.

Features:
- Results update in real-time as you exit insert mode
- Clear visual distinction between code and results
- Easy to toggle visibility when needed
- Errors are highlighted differently from successful results

### Debug Mode

Debug mode lets you step through code execution line by line:
1. Toggle debug mode with `<leader>sd`
2. Execute code with `<CR>`
3. Each line will be highlighted as it executes
4. Press any key to continue to the next line

### Window Position Memory

When you hide and re-toggle a scratch buffer, it will:
1. Remember its previous position and size
2. Restore with the same dimensions
3. Maintain all your code and settings

### Managing Scratch Files

- Save named scratch files with `<leader>ss`
- Browse and manage scratch files with `:ScratchSelect` or `:ScratchSelectNamed`
- Delete files directly from the selection interface with `Ctrl-X`
- Clear unnamed scratch files with `<leader>sx`

## ⌨️ For Developers

Scratch.nvim is designed to be extensible. You can:

- Add support for more languages by extending the `interpreters` table
- Create filetype-specific configurations with `win_by_ft`
- Customize the UI and behavior to match your workflow

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest enhancements
- Add support for more languages
- Submit pull requests

## 📄 License

MIT License - See LICENSE for details 