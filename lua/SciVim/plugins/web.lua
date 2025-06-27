return {
  {
    "brianhuster/live-preview.nvim",
    config = function()
      require("livepreview.config").set({
        port = 5500,
        browser = "qutebrowser",
        dynamic_root = true,
        sync_scroll = true,
        picker = "fzf-lua",
      })
    end,
  }
}
