-- lua/zk/notes.lua
-- Note lifecycle: create, rename, daily

local M        = {}
local index    = require("zk.index")
local template = require("zk.template")

local function cfg() return require("zk").config end

--- Generate a unique ID based on config strategy
---@param title string
---@return string
local function gen_id(title)
  local style = cfg().id_style
  if style == "uuid" then
    -- simple UUID v4 (no external dep)
    local t = {}
    for _ = 1, 32 do t[#t + 1] = string.format("%x", math.random(0, 15)) end
    t[13] = "4"
    t[17] = string.format("%x", bit.band(math.random(0, 15), 0x3) + 8)
    return table.concat(t):gsub("(%w%w%w%w)(%w%w%w%w)(%w%w%w%w)(%w%w%w%w)(%w%w%w%w%w%w%w%w%w%w%w%w)", "%1-%2-%3-%4-%5")
  elseif style == "slug" then
    return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", ""):sub(1, 40)
  else
    -- timestamp YYYYMMDDHHmmss
    return os.date("%Y%m%d%H%M%S")
  end
end

--- Slugify a title for filename
---@param title string
---@return string
local function slugify(title)
  return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", ""):sub(1, 60)
end

--- Internal: write and open a note file
---@param title string
---@param kind? string template kind
local function create_and_open(title, kind)
  local id   = gen_id(title)
  local slug = slugify(title)
  local dir  = cfg().dir
  local ext  = cfg().extension
  local path = dir .. "/" .. slug .. ext

  -- Avoid clobbering existing files
  local i    = 1
  while vim.fn.filereadable(path) == 1 do
    path = string.format("%s/%s-%d%s", dir, slug, i, ext)
    i = i + 1
  end

  local content = template.render(kind or "default", {
    id    = id,
    title = title,
    date  = os.date("%Y-%m-%d"),
  })

  local fd = io.open(path, "w")
  if not fd then
    vim.notify("[ZK] Could not create file: " .. path, vim.log.levels.ERROR)
    return
  end
  fd:write(content)
  fd:close()
  index.update_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  vim.cmd("normal! G$")
  vim.notify("[ZK] Created: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
end

--- Create a new note, optionally with a given title and template kind
---@param title? string
---@param kind?  string template kind (default/daily/meeting/literature/fleeting)
function M.new_note(title, kind)
  if not title then
    vim.ui.input({ prompt = "Note title: " }, function(input)
      if not input or input == "" then return end
      -- If no explicit kind and templates exist, offer picker
      if not kind and cfg().pick_template then
        template.pick(function(k) create_and_open(input, k) end)
      else
        create_and_open(input, kind)
      end
    end)
    return
  end
  create_and_open(title, kind)
end

--- Create note with explicit template picker
function M.new_note_from_template()
  vim.ui.input({ prompt = "Note title: " }, function(title)
    if not title or title == "" then return end
    template.pick(function(kind) create_and_open(title, kind) end)
  end)
end

--- Rename the current note (updates filename + frontmatter title + all links in vault)
---@param new_title? string
function M.rename_note(new_title)
  local cur_path = vim.api.nvim_buf_get_name(0)
  if not cur_path:match("%.md$") then
    vim.notify("[ZK] Not a markdown file", vim.log.levels.WARN)
    return
  end

  local note      = index._notes[cur_path]
  local old_title = note and note.title or vim.fn.fnamemodify(cur_path, ":t:r")
  local old_id    = note and note.id or vim.fn.fnamemodify(cur_path, ":t:r")
  local old_stem  = vim.fn.fnamemodify(cur_path, ":t:r")

  local function do_rename(title)
    if not title or title == "" then return end
    local dir      = cfg().dir
    local ext      = cfg().extension
    local new_slug = slugify(title)
    local new_path = dir .. "/" .. new_slug .. ext

    -- 1. Rename file
    if vim.fn.filereadable(new_path) == 1 and new_path ~= cur_path then
      vim.notify("[ZK] File already exists: " .. new_path, vim.log.levels.ERROR)
      return
    end
    vim.fn.rename(cur_path, new_path)

    -- 2. Update frontmatter title in new file
    local lines = vim.fn.readfile(new_path)
    local in_fm = false
    for i2, line in ipairs(lines) do
      if i2 == 1 and line:match("^---") then
        in_fm = true
      elseif in_fm then
        if line:match("^---") or line:match("^%.%.%.") then break end
        if line:match("^title:") then
          lines[i2] = "title: " .. title
          break
        end
      end
    end
    vim.fn.writefile(lines, new_path)

    -- 3. Update [[wikilinks]] across vault
    local new_stem = vim.fn.fnamemodify(new_path, ":t:r")
    local all = index.all()
    for _, n in ipairs(all) do
      if n.path ~= cur_path then
        local content = table.concat(vim.fn.readfile(n.path), "\n")
        local changed = false
        -- replace [[old_stem]] and [[old_id]]
        for _, old_ref in ipairs({ old_stem, old_id }) do
          local escaped = old_ref:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
          local new_content = content:gsub("%[%[" .. escaped .. "([|%]])", "[[" .. new_stem .. "%1")
          if new_content ~= content then
            content = new_content; changed = true
          end
        end
        if changed then
          vim.fn.writefile(vim.split(content, "\n"), n.path)
        end
      end
    end

    -- 4. Re-index and reopen
    index.remove_file(cur_path)
    index.update_file(new_path)
    vim.cmd("edit " .. vim.fn.fnameescape(new_path))
    vim.notify(string.format("[ZK] Renamed '%s' → '%s'", old_title, title), vim.log.levels.INFO)
  end

  if new_title then
    do_rename(new_title)
  else
    vim.ui.input({ prompt = "New title: ", default = old_title }, do_rename)
  end
end

--- Open or create today's daily note
function M.daily_note()
  local date  = os.date("%Y-%m-%d")
  local title = "Daily " .. date
  local dir   = cfg().dir
  local ext   = cfg().extension
  local path  = dir .. "/" .. date .. ext

  if vim.fn.filereadable(path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  else
    local id = date:gsub("-", "")
    local content = cfg().template(id, title)
        .. "## Tasks\n\n- [ ] \n\n## Notes\n\n"
    local fd = io.open(path, "w")
    if fd then
      fd:write(content)
      fd:close()
      index.update_file(path)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.cmd("normal! G$")
    vim.notify("[ZK] Daily note: " .. date, vim.log.levels.INFO)
  end
end

return M
