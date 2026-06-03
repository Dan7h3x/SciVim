-- lua/zk/init.lua
-- Public API + setup

local M = {}

--- Default configuration
M.config = {
  -- Root directory for notes (resolved to absolute on setup)
  dir = vim.fn.expand("~/notes"),

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
}

--- One-time setup called by user
---@param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  M.config.dir = vim.fn.expand(M.config.dir)

  -- Ensure notes dir exists
  vim.fn.mkdir(M.config.dir, "p")

  -- Register keymaps
  local km = M.config.keymaps
  if km then
    local function map(lhs, fn, desc)
      if lhs then
        vim.keymap.set("n", lhs, fn, { desc = "[ZK] " .. desc, silent = true })
      end
    end
    map(km.new_note, function() require("zk.notes").new_note() end, "New note")
    map(km.find_note, function() require("zk.picker").find_notes() end, "Find note")
    map(km.grep_notes, function() require("zk.picker").grep_notes() end, "Grep notes")
    map(km.backlinks, function() require("zk.picker").backlinks() end, "Backlinks")
    map(km.graph, function() require("zk.graph").open() end, "Graph view")
    map(km.rename_note, function() require("zk.notes").rename_note() end, "Rename note")
    map(km.insert_link, function() require("zk.picker").insert_link() end, "Insert link")
    map(km.daily, function() require("zk.notes").daily_note() end, "Daily note")
    map(km.tags, function() require("zk.picker").find_by_tag() end, "Find by tag")

    -- Follow link under cursor (buffer-local, markdown only)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function(ev)
        if km.follow_link then
          vim.keymap.set("n", km.follow_link, function()
            require("zk.links").follow_link()
          end, { buffer = ev.buf, desc = "[ZK] Follow link", silent = true })
        end
      end,
    })
  end

  -- Completion for [[ wiki-links
  if M.config.link_completion then
    require("zk.completion").setup()
  end

  -- Buffer-local commands
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function() require("zk.buf").attach() end,
  })
end

--- Register vim commands (always runs, even without setup())
function M.setup_commands()
  local cmds = {
    ZkNew             = function(a) require("zk.notes").new_note(a.args ~= "" and a.args or nil) end,
    ZkNewFromTemplate = function() require("zk.notes").new_note_from_template() end,
    ZkFind            = function() require("zk.picker").find_notes() end,
    ZkGrep            = function(a) require("zk.picker").grep_notes(a.args ~= "" and a.args or nil) end,
    ZkBacklinks       = function() require("zk.picker").backlinks() end,
    ZkGraph           = function() require("zk.graph").open() end,
    ZkDaily           = function() require("zk.notes").daily_note() end,
    ZkTags            = function() require("zk.picker").find_by_tag() end,
    ZkRename          = function(a) require("zk.notes").rename_note(a.args ~= "" and a.args or nil) end,
    ZkInsertLink      = function() require("zk.picker").insert_link() end,
    ZkIndex           = function() require("zk.index").rebuild(true) end,
  }
  for name, fn in pairs(cmds) do
    vim.api.nvim_create_user_command(name, fn, { nargs = "?", desc = "[ZK] " .. name })
  end
end

return M
