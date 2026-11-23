return {
  {
    dir = "~/.config/nvim/lua/zk/",
    lazy = false,

    opts = {
      -- Root directory for notes (resolved to absolute on setup)
      dir = vim.fn.expand("~/Desktop/MyNotes/"),

      -- File extension for notes
      extension = ".md",

      -- Template for new notes (id and title are injected)
      template = function(id, title)
        return string.format(
          "---\nid: %s\ntitle: %s\ndate: %s\ntags: []\n---\n\n# %s\n\n",
          id,
          title,
          os.date("%Y-%m-%d"),
          title
        )
      end,

      -- ID generation strategy: "timestamp" | "uuid" | "slug"
      id_style = "timestamp",

      -- Picker to use: "snacks" | "fzf" | "telescope" | "vim"
      -- Auto-detected if nil
      picker = nil,

      -- Graph viewer: "browser" (opens HTML) | "kitty" (sixel/kitty graphics)
      graph_viewer = "browser",

      -- Whether to auto-create links as you type [[
      link_completion = true,

      -- Keymaps (set to false to disable all, or override individual keys)
      keymaps = {
        follow_link = "<CR>",
        new_note    = "<leader>zn",
        find_note   = "<leader>zf",
        grep_notes  = "<leader>zg",
        backlinks   = "<leader>zb",
        graph       = "<leader>zG",
        rename_note = "<leader>zr",
        insert_link = "<leader>zl",
        daily       = "<leader>zd",
        tags        = "<leader>zt",
      },
    },
    config = function(_, opts)
      require("zk").setup(opts)
    end
  }
}
