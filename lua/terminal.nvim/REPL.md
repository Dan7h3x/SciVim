# REPL Features - terminal.nvim

Comprehensive REPL (Read-Eval-Print-Loop) support for interactive programming in Neovim.

## 🎯 Overview

Terminal.nvim provides first-class REPL support for 15+ programming languages with features like:

- Auto-detection from buffer filetype
- Persistent command history
- Auto-import common libraries (Python, IPython)
- Bracketed paste for multiline code
- Language-specific optimizations
- Send line, selection, paragraph, or entire buffer
- Execute files directly in REPL

## 📚 Supported Languages

### Fully Supported

| Language   | REPL      | Special Features             |
| ---------- | --------- | ---------------------------- |
| Python     | `python3` | Auto-import, bracketed paste |
| IPython    | `ipython` | Magic commands, auto-import  |
| JavaScript | `node`    | Async/await wrapping         |
| Lua        | `lua`     | Auto return values           |
| Ruby       | `irb`     | Bracketed paste              |
| Julia      | `julia`   | -                            |
| R          | `R`       | Quiet mode                   |
| Bash       | `bash`    | Custom prompt                |
| Zsh        | `zsh`     | Custom prompt                |
| Haskell    | `ghci`    | Multiline support            |
| Scheme     | `guile`   | -                            |
| Racket     | `racket`  | -                            |
| Clojure    | `clojure` | -                            |
| OCaml      | `ocaml`   | -                            |
| Scala      | `scala`   | -                            |
| Elixir     | `iex`     | Double Ctrl-C support        |
| Erlang     | `erl`     | -                            |

## 🚀 Quick Start

### Basic Usage

```lua
local term = require('terminal')

-- Setup
term.setup({
  repl = {
    auto_start = true,      -- Auto-start REPL when sending code
    save_history = true,    -- Save command history
  }
})

-- Start REPL (auto-detects from buffer filetype)
term.repl_start()

-- Send current line
term.repl_send_line()

-- Send visual selection
term.repl_send_selection()
```

### Language-Specific

```lua
-- Python with auto-import
term.repl_start('python')

-- IPython with magic commands
term.repl_start('ipython', {
  direction = 'vertical',
  size = 80,
})

-- Node.js REPL
term.repl_start('node', {
  direction = 'float',
})
```

## ⚙️ Configuration

### Global Configuration

```lua
require('terminal').setup({
  repl = {
    -- Auto-start REPL when sending code
    auto_start = true,

    -- Auto-close REPL when buffer closes
    auto_close = false,

    -- Save command history to file
    save_history = true,

    -- History file path
    history_file = vim.fn.stdpath('data') .. '/terminal_repl_history',

    -- Default keymaps
    keymaps = {
      send_line = '<leader>rl',
      send_selection = '<leader>rs',
      send_paragraph = '<leader>rp',
      send_buffer = '<leader>rb',
      toggle_repl = '<leader>rt',
      clear_repl = '<leader>rc',
      interrupt = '<leader>ri',
      exit = '<leader>rq',
    },
  }
})
```

### Language-Specific Configuration

```lua
-- Custom Python REPL
term.repl_start('python', {
  direction = 'vertical',
  size = 80,
}, {
  auto_import = true,
  startup_commands = {
    'import sys',
    'sys.path.insert(0, "/custom/path")',
  },
  code_wrapper = function(code)
    -- Transform code before sending
    return code
  end,
})
```

## 📖 API Reference

### Starting REPLs

```lua
-- Auto-detect from current buffer's filetype
term.repl_start()

-- Specific language
term.repl_start('python')
term.repl_start('ipython')
term.repl_start('node')

-- With terminal options
term.repl_start('python', {
  direction = 'float',
  size = 30,
})

-- With REPL configuration
term.repl_start('python', nil, {
  auto_import = true,
  startup_commands = {
    'print("REPL started")',
  },
})
```

### Sending Code

```lua
-- Send current line
term.repl_send_line()

-- Send visual selection
term.repl_send_selection()

-- Send paragraph (blank-line separated block)
term.repl_send_paragraph()

-- Send entire buffer
term.repl_send_buffer()
```

### REPL Control

```lua
-- Toggle visibility
term.repl_toggle()
term.repl_toggle('python')

-- Clear screen
term.repl_clear()

-- Interrupt execution (Ctrl-C)
term.repl_interrupt()

-- Exit REPL
term.repl_exit()
term.repl_exit('python')
```

### Direct REPL Access

```lua
-- Get REPL instance
local python_repl = term.repl_get('python')

-- Send code
python_repl:send('import numpy as np')
python_repl:send({
  'x = np.array([1, 2, 3])',
  'print(x.mean())',
})

-- Execute file
python_repl:execute_file('/path/to/script.py')

-- Execute current buffer
python_repl:execute_buffer()

-- Navigation
python_repl:open()
python_repl:close()
python_repl:toggle()
python_repl:focus()

-- History
local prev = python_repl:history_prev()
local next = python_repl:history_next()
python_repl:history_clear()

-- Control
python_repl:clear()
python_repl:interrupt()
python_repl:exit()
```

## 🎨 Workflows

### Data Science with Python

```lua
vim.keymap.set('n', '<leader>rds', function()
  require('terminal').repl_start('ipython', {
    direction = 'vertical',
    size = 80,
  }, {
    auto_import = true,
    startup_commands = {
      'import numpy as np',
      'import pandas as pd',
      'import matplotlib.pyplot as plt',
      'import seaborn as sns',
      '%matplotlib inline',
      '%load_ext autoreload',
      '%autoreload 2',
    },
  })
end, { desc = 'Start data science REPL' })
```

### JavaScript Development

```lua
vim.keymap.set('n', '<leader>rjs', function()
  require('terminal').repl_start('node', {
    direction = 'float',
    cwd = vim.fn.getcwd(),
  })
end, { desc = 'Start JavaScript REPL' })
```

### Send and Execute

```lua
-- Send line and move to next
vim.keymap.set('n', '<leader>re', function()
  require('terminal').repl_send_line()
  vim.cmd('normal! j')
end, { desc = 'Send line and move down' })

-- Execute entire buffer
vim.keymap.set('n', '<F5>', function()
  require('terminal').repl_send_buffer()
end, { desc = 'Execute buffer in REPL' })
```

### Interactive Testing

```lua
-- Send test function and run it
vim.keymap.set('n', '<leader>rtt', function()
  local term = require('terminal')
  term.repl_send_paragraph()  -- Send test definition
  vim.defer_fn(function()
    term.repl_send_line()     -- Run the test
  end, 100)
end, { desc = 'Send test and run' })
```

## 🔧 Language-Specific Features

### Python / IPython

- **Auto-import**: Automatically imports numpy, pandas, matplotlib
- **Bracketed paste**: Safe multiline code handling
- **Magic commands**: IPython magic commands work out of the box

```lua
term.repl_start('ipython', nil, {
  auto_import = true,
  startup_commands = {
    '%load_ext autoreload',
    '%autoreload 2',
    '%matplotlib inline',
  },
})
```

### Node.js

- **Async/await**: Automatically wraps async code
- **IIFE wrapping**: Clean scope management

```lua
term.repl_start('node')
-- Send: await fetch('https://api.example.com')
-- Automatically wrapped in async IIFE
```

### Haskell

- **Multiline support**: Use `:{ }:` for multiline definitions
- **File loading**: `:load` command support

```lua
term.repl_start('haskell', nil, {
  startup_commands = {
    ':set prompt "λ> "',
  },
})
```

## 🎯 Advanced Usage

### Custom Code Transformation

```lua
term.repl_start('python', nil, {
  code_wrapper = function(code)
    -- Add timing to all code
    return 'import time; start = time.time(); ' ..
           code ..
           '; print(f"Executed in {time.time() - start:.4f}s")'
  end,
})
```

### Output Monitoring

```lua
term.repl_start('python', {
  on_stdout = function(terminal, job_id, data)
    for _, line in ipairs(data) do
      if line:match('Error') or line:match('Exception') then
        vim.notify('Error detected: ' .. line, vim.log.levels.ERROR)
      end
    end
  end,
})
```

### Multiple REPLs

```lua
-- Run Python, Node, and R simultaneously
term.repl_start('python', { direction = 'horizontal' })
term.repl_start('node', { direction = 'vertical' })
term.repl_start('r', { direction = 'float' })
```

## 📝 Tips and Tricks

### 1. Filetype Detection

REPL automatically detects the appropriate language from your buffer's filetype:

```lua
-- In a .py file
term.repl_start()  -- Starts Python REPL

-- In a .js file
term.repl_start()  -- Starts Node REPL
```

### 2. Persistent History

Command history persists across Neovim sessions when `save_history = true`.

### 3. Bracketed Paste

Enabled automatically for supported REPLs. Prevents issues with pasting indented code.

### 4. Multiline Input

Different approaches for different languages:

- **IPython**: `%cpaste` and `--`
- **Haskell**: `:{` and `:}`
- **Most others**: Just paste the code

### 5. Execute Files

```lua
local repl = term.repl_get('python')
repl:execute_file('/path/to/script.py')
repl:execute_buffer()  -- Current buffer
```

### 6. Auto-Start

With `auto_start = true`, REPLs start automatically when you send code:

```lua
-- No need to call repl_start() first
term.repl_send_line()  -- Auto-starts REPL if needed
```

### 7. Buffer-Local Keymaps

Keymaps are automatically set up for supported filetypes:

```lua
-- Open a .py file, keymaps are ready
<leader>rl  -- Send line
<leader>rs  -- Send selection
```

## 🐛 Troubleshooting

### REPL Not Starting

- Ensure the REPL command is in your PATH
- Check terminal options: `term.repl_start('python', { shell = '/bin/bash' })`

### Multiline Code Issues

- Enable bracketed paste: already enabled for most REPLs
- For IPython, use `%cpaste` mode
- For Haskell, use `:{ }:` blocks

### History Not Saving

- Check `save_history = true` in configuration
- Verify write permissions for history file

### Import Errors (Python)

- Disable auto-import: `auto_import = false`
- Check your Python environment

## 📚 Examples

See `examples/repl_examples.lua` for comprehensive examples including:

- All supported languages
- Workflow setups
- Custom configurations
- Keymapping patterns
- Integration patterns

## 🤝 Contributing

To add support for a new language:

1. Add configuration to `lua/terminal/repl.lua`:

```lua
TerminalRepl.language_configs.newlang = {
  command = 'newlang-repl',
  prompt_pattern = '> ',
  -- ... other config
}
```

2. Add filetype mapping in `lua/terminal/repl_manager.lua`:

```lua
function ReplManager:_filetype_to_language(filetype)
  local map = {
    -- ...
    newlang = 'newlang',
  }
  return map[filetype]
end
```

## 📄 License

MIT License - See LICENSE file for details
