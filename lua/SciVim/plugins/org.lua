-- ~/.config/nvim/lua/plugins/org.lua
return {
  "xheisenbugx/org.nvim",
  main = "org",
  ft = { "org" },
  opts = {
    org_directory = "~/Desktop/MyNotes/",
    agenda_files = { "~/Desktop/MyAgenda/**/*.org" },
    default_notes_file = "~/Desktop/MyNotes/default.org",

    todo_keywords = { "TODO(t) NEXT(n) WAITING(w@/!) | DONE(d!) CANCELLED(c@)" },
    log_done = "time", -- false | "time" | "note"
    log_into_drawer = "LOGBOOK",
    tags = { "work(w)", "home(h)", "{", "@office(o)", "@remote(r)", "}" },
    tags_column = -77,
    startup_folded = "overview",
    deadline_warning_days = 14,

    agenda = { span = "week", start_on_weekday = 1, window = "current" },
    capture = { templates = { --[[ see below ]] } },
    refile = { max_level = 3 },
    notifications = { enabled = true, reminder_time = { 10, 0 } },

    ui = {
      bullets = { "◉", "○", "✸", "✿" }, -- or false
      checkboxes = { " ", "◐", "✓" }, -- or false
      hide_emphasis_markers = false,
      indent_mode = false, -- org-indent-mode
      todo_keyword_faces = { WAITING = ":foreground #e0af68 :weight bold" },
    },

    mappings = {
      prefix = "<leader>o",
      org = { toggle_checkbox = "<C-Space>", open_at_point = { "<CR>", "gx" } },
      agenda = { goto_date = "gd" },
    },
  },
}
