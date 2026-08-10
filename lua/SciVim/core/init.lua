-- Core config of SciVim

require("SciVim.core.options")
require("SciVim.core.keymaps")
require("SciVim.core.autocmds")
require("SciVim.core.lazy")
require("SciVim.extras.notifs").setup()
require("SciVim.extras.markex").setup({
  -- Output formatting
  output = {
    -- Style for output section
    style = 'minimal', -- 'fancy', 'minimal', 'simple'
    -- Show execution time
    show_execution_time = false,
    -- Show exit code
    show_exit_code = true,
    -- Show timestamp
    show_timestamp = false,
    -- Box drawing characters
    box = {
      horizontal = '─',
      vertical = '│',
      top_left = '╭',
      top_right = '╮',
      bottom_left = '╰',
      bottom_right = '╯',
      title_left = '┤',
      title_right = '├',
    },
    -- Colors (using highlight groups)
    highlights = {
      border = 'MarkdownRunnerBorder',
      title = 'MarkdownRunnerTitle',
      stdout = 'MarkdownRunnerStdout',
      stderr = 'MarkdownRunnerStderr',
      timestamp = 'MarkdownRunnerTimestamp',
      exit_success = 'MarkdownRunnerSuccess',
      exit_error = 'MarkdownRunnerError',
      spinner = 'MarkdownRunnerSpinner',
    },
  },
  -- Virtual text for status
  virtual_text = {
    enabled = true,
    running_icon = '⚡',
    success_icon = '✅',
    error_icon = '❌',
    position = 'right_align', -- 'eol', 'right_align', 'overlay'
  },
  -- Progress indication
  progress = {
    spinner = true,
    spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
    spinner_interval = 80,
    progress_bar = true,
    progress_bar_width = 20,
  },
  -- Auto commands
  auto_run = false,         -- Auto run on save?
  auto_clear_on_run = true, -- Clear previous output before re-run?
  -- Keymaps
  keymaps = {
    run_current_block = '<leader>mb',
    run_all_blocks = '<leader>ma',
    clear_outputs = '<leader>mc',
    toggle_output_style = '<leader>mt',
  },
  -- File type to attach
  filetypes = { 'markdown', 'md' },
  -- Maximum output lines to show (0 = unlimited)
  max_output_lines = 50,
  -- Default timeout in seconds
  timeout = 30,
})

-- require("SciVim.extras.wr").setup({})
-- require("SciVim.extras.present").setup()
require("SciVim.extras.dashboard")
if vim.g.neovide then
  vim.o.cmdheight = 1
  vim.g.neovide_opacity = 0.89
  vim.g.neovide_normal_opacity = 0.89
end
