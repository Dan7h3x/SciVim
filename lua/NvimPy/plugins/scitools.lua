return {
    {
        "frabjous/knap", -- LaTeX builder and previewer
        event = "VeryLazy"
    },
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
                            command = {"zsh"}
                        },
                        python = fts.python.ipython
                    },
                    -- How the repl window will be displayed
                    -- See below for more information
                    repl_open_cmd = view.split("35%", {
                        winfixwidth = true,
                        winfixheight = true,
                        number = false
                    })
                },
                -- Iron doesn't set keymaps by default anymore.
                -- You can set them here or manually add keymaps to the functions in iron.core
                keymaps = {
                    send_file = "<space>x",
                    send_line = "<space>X",
                },
                -- If the highlight is on, you can change how it looks
                -- For the available options, check nvim_set_hl
                highlight = {italic = true},
                ignore_blank_lines = true -- ignore blank lines when sending visual select lines
            })
        end
    }
}
