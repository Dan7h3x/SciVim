return {
  {
    "Vigemus/iron.nvim",
    event = "VeryLazy",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local fts = require("iron.fts")
      iron.setup({
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          -- Your repl definitions come here
          repl_definition = {
            sh = {
              -- Can be a table or a function that
              -- returns a table (see below)
              command = { "zsh" },
            },
            python = fts.python.ipython,
          },
          -- How the repl window will be displayed
          -- See below for more information
          repl_open_cmd = view.split("%30", {
            winfixwidth = true,
            winfixheight = true,
            number = false,
          }),
        },
        -- Iron doesn't set keymaps by default anymore.
        -- You can set them here or manually add keymaps to the functions in iron.core
        keymaps = {
          send_file = "<space>rt",
          send_line = "<space>rl",
          send_until_cursor = "<space>rc",
          exit = "<space>rq",
          send_motion = "<space>re",
        },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = { italic = true },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      })
    end,
  },
  ---[
  --- Treesitter for VimTeX
  ---]
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.highlight = opts.highlight or {}
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "bibtex" })
      end
      if type(opts.highlight.disable) == "table" then
        vim.list_extend(opts.highlight.disable, { "latex" })
      else
        opts.highlight.disable = { "latex" }
      end
    end,
  },
  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      -- vim.g.vimtex_compiler_silent = 1
      -- vim.g.vimtex_complete_bib = {
      -- 	simple = 1,
      -- 	menu_fmt = "@year, @author_short, @title",
      -- }
      -- vim.g.vimtex_context_pdf_viewer = "zathura"
      -- vim.g.vimtex_doc_handlers = { "vimtex#doc#handlers#texdoc" }
      -- vim.g.vimtex_fold_enabled = 1
      -- vim.g.vimtex_fold_types = {
      -- 	markers = { enabled = 0 },
      -- 	sections = { parse_levels = 1 },
      -- }
      -- vim.g.vimtex_format_enabled = 1
      -- vim.g.vimtex_imaps_leader = "¨"
      vim.g.vimtex_imaps_list = {
        {
          lhs = "ii",
          rhs = "\\item ",
          leader = "",
          wrapper = "vimtex#imaps#wrap_environment",
          context = { "itemize", "enumerate", "description" },
        },
        { lhs = ".", rhs = "\\cdot" },
        { lhs = "*", rhs = "\\times" },
        { lhs = "a", rhs = "\\alpha" },
        { lhs = "r", rhs = "\\rho" },
        { lhs = "p", rhs = "\\varphi" },
      }
      -- vim.g.vimtex_quickfix_open_on_warning = 0
      -- vim.g.vimtex_quickfix_ignore_filters = { "Generic hook" }
      -- vim.g.vimtex_syntax_conceal_disable = 1
      -- vim.g.vimtex_toc_config = {
      -- 	split_pos = "full",
      -- 	mode = 2,
      -- 	fold_enable = 1,
      -- 	show_help = 0,
      -- 	hotkeys_enabled = 1,
      -- 	hotkeys_leader = "",
      -- 	refresh_always = 0,
      -- }
      -- vim.g.vimtex_view_automatic = 0
      -- vim.g.vimtex_view_forward_search_on_start = 0
      -- vim.g.vimtex_view_method = "zathura"
      --
      -- vim.g.vimtex_grammar_vlty = {
      -- 	lt_command = "languagetool",
      -- 	show_suggestions = 1,
      -- }
      --
      -- vim.api.nvim_create_autocmd("User", {
      -- 	group = vim.api.nvim_create_augroup("init_vimtex", {}),
      -- 	pattern = "VimtexEventViewReverse",
      -- 	desc = "VimTeX: Center view on inverse search",
      -- 	command = [[ normal! zMzvzz ]],
      -- })
    end,
    ft = "tex",
  },
}
