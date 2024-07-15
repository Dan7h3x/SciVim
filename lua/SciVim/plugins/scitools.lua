return {
  -- {
  -- 	"frabjous/knap", -- LaTeX builder and previewer
  -- 	lazy = true,
  -- 	keys = {
  -- 		{
  -- 			"<F2>",
  -- 			function()
  -- 				require("knap").process_once()
  -- 			end,
  -- 			desc = "LaTeX Process",
  -- 		},
  -- 		{
  -- 			"<F3>",
  -- 			function()
  -- 				require("knap").close_viewer()
  -- 			end,
  -- 			desc = "Close Viewer",
  -- 		},
  -- 		{
  -- 			"<F4>",
  -- 			function()
  -- 				require("knap").toggle_autopreviewing()
  -- 			end,
  -- 			desc = "Toggle Autopreviewing",
  -- 		},
  -- 		{
  -- 			"<F5>",
  -- 			function()
  -- 				require("knap").forward_jump()
  -- 			end,
  -- 			desc = "SyncTex",
  -- 		},
  -- 	},
  -- },
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
}
