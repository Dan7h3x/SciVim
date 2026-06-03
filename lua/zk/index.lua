-- lua/zk/index.lua
-- Scans the vault and maintains an in-memory index of notes, links, and tags.
-- Index is lazy-built on first access and invalidated via fs-watch.

local M    = {}
local uv   = vim.uv or vim.loop

---@class ZkNote
---@field id string
---@field path string
---@field title string
---@field tags string[]
---@field date string
---@field links string[]   ids this note links to
---@field mtime number

-- { [path]: ZkNote }
M._notes   = {}
-- { [id]: path }
M._id_map  = {}
-- built flag
M._built   = false
-- fs-watcher handle
M._watcher = nil

--- Return config shortcut
local function cfg() return require("zk").config end

--- Parse YAML-ish frontmatter from markdown content
---@param content string
---@return table
local function parse_frontmatter(content)
  local fm = {}
  local in_fm = false
  local line_no = 0
  for line in content:gmatch("([^\n]*)\n?") do
    line_no = line_no + 1
    if line_no == 1 then
      if line:match("^---") then in_fm = true end
    elseif in_fm then
      if line:match("^---") or line:match("^%.%.%.") then break end
      local key, val = line:match("^(%w+):%s*(.*)$")
      if key then
        -- handle list values like tags: [a, b] or tags:\n  - a
        if val:match("^%[(.*)%]$") then
          local items = {}
          for item in val:match("^%[(.*)%]$"):gmatch("[^,]+") do
            table.insert(items, vim.trim(item))
          end
          fm[key] = items
        else
          fm[key] = vim.trim(val)
        end
      end
      -- inline list items "- tag"
      local tag = line:match("^%s*-%s+(.+)$")
      if tag and fm.tags and type(fm.tags) == "table" then
        table.insert(fm.tags, vim.trim(tag))
      end
    end
  end
  return fm
end

--- Extract [[wikilinks]] and [text](path) markdown links from content
---@param content string
---@return string[]
local function extract_links(content)
  local links = {}
  local seen = {}
  -- [[target]] or [[target|alias]]
  for target in content:gmatch("%[%[([^%]|]+)[^%]]*%]%]") do
    local t = vim.trim(target)
    if not seen[t] then
      seen[t] = true; table.insert(links, t)
    end
  end
  -- [text](target.md) — strip extension and path
  for target in content:gmatch("%[.-%]%(([^)]+)%)") do
    target = target:match("^(.-)%.md$") or target
    target = vim.fn.fnamemodify(target, ":t:r")
    if not seen[target] then
      seen[target] = true; table.insert(links, target)
    end
  end
  return links
end

--- Extract first H1 heading as title fallback
---@param content string
---@return string?
local function extract_h1(content)
  return content:match("^#%s+(.+)$") or content:match("\n#%s+(.+)\n")
end

--- Index a single file
---@param path string
local function index_file(path)
  local fd = io.open(path, "r")
  if not fd then return end
  local content = fd:read("*a")
  fd:close()

  local stat     = uv.fs_stat(path)
  local mtime    = stat and stat.mtime.sec or 0

  local fm       = parse_frontmatter(content)
  local id       = fm.id or vim.fn.fnamemodify(path, ":t:r")
  local title    = fm.title or extract_h1(content) or id
  local tags     = type(fm.tags) == "table" and fm.tags or {}
  local links    = extract_links(content)

  ---@type ZkNote
  local note     = {
    id    = id,
    path  = path,
    title = title,
    tags  = tags,
    date  = fm.date or "",
    links = links,
    mtime = mtime,
  }

  M._notes[path] = note
  M._id_map[id]  = path
  -- also map by filename stem for wikilinks that use filename
  local stem     = vim.fn.fnamemodify(path, ":t:r")
  if stem ~= id then M._id_map[stem] = path end
end

--- Walk the vault directory recursively
local function walk(dir, cb)
  local handle = uv.fs_scandir(dir)
  if not handle then return end
  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then break end
    local full = dir .. "/" .. name
    if typ == "directory" and not name:match("^%.") then
      walk(full, cb)
    elseif typ == "file" and name:match("%.md$") then
      cb(full)
    end
  end
end

--- Build full index
---@param verbose? boolean
function M.rebuild(verbose)
  local dir   = cfg().dir
  M._notes    = {}
  M._id_map   = {}
  local count = 0
  walk(dir, function(path)
    index_file(path)
    count = count + 1
  end)
  M._built = true
  if verbose then
    vim.notify(string.format("[ZK] Indexed %d notes in %s", count, dir), vim.log.levels.INFO)
  end
end

--- Ensure index is ready
function M.ensure()
  if not M._built then M.rebuild() end
end

--- Get all notes as list
---@return ZkNote[]
function M.all()
  M.ensure()
  local list = {}
  for _, n in pairs(M._notes) do table.insert(list, n) end
  table.sort(list, function(a, b)
    return (a.date ~= "" and b.date ~= "") and a.date > b.date or a.title < b.title
  end)
  return list
end

--- Resolve an id/stem/title to a note
---@param ref string
---@return ZkNote?
function M.resolve(ref)
  M.ensure()
  -- exact id / stem
  local path = M._id_map[ref]
  if path then return M._notes[path] end
  -- fuzzy title match
  ref = ref:lower()
  for _, note in pairs(M._notes) do
    if note.title:lower() == ref then return note end
  end
  for _, note in pairs(M._notes) do
    if note.title:lower():find(ref, 1, true) then return note end
  end
  return nil
end

--- Get notes that link TO the given note id
---@param id string
---@return ZkNote[]
function M.backlinks(id)
  M.ensure()
  local result = {}
  for _, note in pairs(M._notes) do
    for _, link in ipairs(note.links) do
      if link == id then
        table.insert(result, note); break
      end
    end
  end
  return result
end

--- Get all unique tags
---@return string[]
function M.all_tags()
  M.ensure()
  local seen = {}
  local tags = {}
  for _, note in pairs(M._notes) do
    for _, tag in ipairs(note.tags) do
      if not seen[tag] then
        seen[tag] = true; table.insert(tags, tag)
      end
    end
  end
  table.sort(tags)
  return tags
end

--- Get notes with a given tag
---@param tag string
---@return ZkNote[]
function M.by_tag(tag)
  M.ensure()
  local result = {}
  for _, note in pairs(M._notes) do
    for _, t in ipairs(note.tags) do
      if t == tag then
        table.insert(result, note); break
      end
    end
  end
  return result
end

--- Re-index a single file (called on save)
---@param path string
function M.update_file(path)
  if not M._built then return end
  index_file(path)
end

--- Remove a note from index
---@param path string
function M.remove_file(path)
  local note = M._notes[path]
  if note then
    M._id_map[note.id] = nil
    local stem = vim.fn.fnamemodify(path, ":t:r")
    M._id_map[stem] = nil
  end
  M._notes[path] = nil
end

--- Setup fs-watcher for live index updates
function M.watch()
  local dir = cfg().dir
  M._watcher = uv.new_fs_event()
  if not M._watcher then return end
  M._watcher:start(dir, { recursive = true }, vim.schedule_wrap(function(err, filename)
    if err or not filename then return end
    if not filename:match("%.md$") then return end
    local full = dir .. "/" .. filename
    local stat = uv.fs_stat(full)
    if stat then
      index_file(full)
    else
      M.remove_file(full)
    end
  end))
end

return M
