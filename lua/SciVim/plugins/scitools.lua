return {
  {
    "Vigemus/iron.nvim",
    ft = { "python", "sh" },
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
              command = { "bash" },
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
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_context_pdf_viewer = "zathura"
      vim.g.vimtex_doc_handlers = { "vimtex#doc#handlers#texdoc" }
      vim.g.vimtex_fold_enabled = 1
      vim.g.vimtex_fold_types = {
        markers = { enabled = 0 },
        sections = { parse_levels = 1 },
      }

      vim.g.vimtex_toc_config = {
        split_pos = "vert leftabove",
        split_width = 33,
        mode = 2,
        fold_enable = 1,
        show_help = 0,
        hotkeys_enabled = 1,
        hotkeys_leader = "'",
        refresh_always = 0,
      }



      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("init_vimtex", {}),
        pattern = "VimtexEventViewReverse",
        desc = "VimTeX: Center view on inverse search",
        command = [[ normal! zMzvzz ]],
      })
    end,
    ft = "tex",
  },
  {
    'anufrievroman/vim-angry-reviewer'
    ,
    -- dependencies = { 'anufrievroman/vim-tex-kawaii' },
    ft = "tex",
    keys = { {
      "<localleader>a", "<Cmd>AngryReviewer<CR>", desc = "AngryReviewer"
    } },
    config = function()
      vim.g.AngryReviewerEnglish = 'american'
    end
  },


}
