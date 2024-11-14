local config = {
  options = {
    icons_enabled = true,
    theme = "auto",
    component_separators = { left = "|", right = "|" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = {
      "alpha",
      "dashboard",
      "Chatter",
      "starter",
      "cmp_menu",
      "neo-tree",
      "Outline",
      "terminal",
      "lazy",
      "undotree",
      "Telescope",
      "dapui*",
      "dapui_scopes",
      "dapui_watches",
      "dapui_console",
      "dapui_breakpoints",
      "dapui_stacks",
      "dap-repl",
      "term",
      "zsh*",
      "bash",
      "shell",
      "terminal",
      "gitsigns-blame",
      "toggleterm",
      "termim",
      "neaterm",
      "REPL",
      "repl",
      "Iron",
      "Ipython",
      "ipython*",
      "diff",
      "qf",
      "spectre_panel",
      "Trouble",
      "help",
      "hoversplit",
      "which_key",
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = vim.o.laststatus == 3,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "filename", "branch", "diff" },
    lualine_c = {},
    lualine_x = {},
    lualine_y = { "encoding", "fileformat", "filetype", "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
}

local Theme = require("SciVim.extras.theme")
local Icons = require("SciVim.extras.icons")
local Tools = require("SciVim.extras.lualine_tools")
local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x at right section
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end

ins_left({
  function()
    return require("tinygit.statusline").blame()
  end,
})

ins_left({
  function()
    return require("pomodoro").statusline()
  end,
  cond = function()
    local pomstat = require("pomodoro").statusline()
    return not string.find(pomstat, "inactive")
  end,
  color = { fg = Theme.blue, gui = "bold" },
  padding = 1,
})
ins_left({
  function()
    return require("dap").status()
  end,
  cond = function()
    return package.loaded["dap"] and require("dap").status() ~= ""
  end,
  icon = { "", color = { fg = Theme.teal } },
  color = { fg = Theme.teal },
  padding = 1,
})
ins_left({
  Tools.lsp_servers_new,
  icon = { " ", color = { fg = Theme.cyan } },
  color = { fg = Theme.magenta, gui = "bold" },
  padding = 1,
})
ins_left({
  "diagnostics",
  sources = { "nvim_lsp" },
  symbols = {
    error = Icons.diagnostics.Error,
    warn = Icons.diagnostics.Warn,
    info = Icons.diagnostics.Info,
    hint = Icons.diagnostics.Hint,
  },
  diagnostics_color = {
    error = { fg = Theme.red },
    warn = { fg = Theme.yellow },
    info = { fg = Theme.blue },
    hint = { fg = Theme.green },
  },
  padding = { left = 1, right = 0 },
})

-- ins_left({
-- 	"diagnostics-message",
-- 	padding = 1,
-- })

ins_right({
  require("lazy.status").updates,
  cond = require("lazy.status").has_updates,
  color = { fg = Theme.orange },
  padding = 1,
})

ins_right({
  function()
    return os.date("%R:%S")
  end,
  color = { fg = Theme.blue },
  icon = { "", color = { fg = Theme.magenta } },
  padding = 1,
})

return {
  {
    "nvim-lualine/lualine.nvim",
    -- event = "VeryLazy",
    event = { "VeryLazy" },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = " "
      else
        vim.o.laststatus = 0
      end
    end,
    config = function()
      vim.o.laststatus = vim.g.lualine_laststatus
      require("lualine").setup(config)
    end,
  },
}
