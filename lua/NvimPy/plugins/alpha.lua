return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    lazy = false,
    enabled = true,
    init = false,
    opts = function()
      local Conf = require("alpha.themes.theta").config
      local path_ok, plenary_path = pcall(require, "plenary.path")
      if not path_ok then
        return
      end
      local Logo = {
        [[╔────────────────────────────────────────────────────────────────────╗]],
        [[│ ██████   █████            ███                ███████████           │]],
        [[│░░██████ ░░███            ░░░                ░░███░░░░░███          │]],
        [[│ ░███░███ ░███ █████ █████████ █████████████  ░███    ░████████ ████│]],
        [[│ ░███░░███░███░░███ ░░███░░███░░███░░███░░███ ░██████████░░███ ░███ │]],
        [[│ ░███ ░░██████ ░███  ░███ ░███ ░███ ░███ ░███ ░███░░░░░░  ░███ ░███ │]],
        [[│ ░███  ░░█████ ░░███ ███  ░███ ░███ ░███ ░███ ░███        ░███ ░███ │]],
        [[│ █████  ░░█████ ░░█████   ██████████░███ ██████████       ░░███████ │]],
        [[│░░░░░    ░░░░░   ░░░░░   ░░░░░░░░░░ ░░░ ░░░░░░░░░░         ░░░░░███ │]],
        [[│                                                           ███ ░███ │]],
        [[│                                                          ░░██████  │]],
        [[╚────────────────────────────────────────────────────────────────────╝]],
      }
      local function lineToStartGradient(lines)
        local out = {}
        for i, line in ipairs(lines) do
          table.insert(out, { hi = "NvimPy" .. i, line = line })
        end
        return out
      end

      local function lineToStartPopGradient(lines)
        local out = {}
        for i, line in ipairs(lines) do
          local hi = "NvimPy" .. i
          if i <= 6 then
            hi = "NvimPy" .. i + 6
          elseif i > 6 and i <= 12 then
            hi = "NvimPyPy" .. i - 6
          end
          table.insert(out, { hi = hi, line = line })
        end
        return out
      end

      local function lineToStartShiftGradient(lines)
        local out = {}
        for i, line in ipairs(lines) do
          local n = i
          if i > 6 and i <= 12 then
            n = i + 6
          elseif i > 12 then
            n = i - 6
          end
          table.insert(out, { hi = "NvimPy" .. n, line = line })
        end
        return out
      end

      local NvimPy1 = lineToStartPopGradient(Logo)
      local NvimPy2 = lineToStartShiftGradient(Logo)
      local NvimPy3 = lineToStartGradient(Logo)
      local Headers = { NvimPy1, NvimPy2, NvimPy3 }

      local function headers_chars()
        math.randomseed(os.time())
        return Headers[math.random(#Headers)]
      end
      local function header_color()
        local lines = {}
        for _, lineConfig in pairs(headers_chars()) do
          local hi = lineConfig.hi
          local line_chars = lineConfig.line
          local line = {
            type = "text",
            val = line_chars,
            opts = {
              hl = hi,
              shrink_margin = false,
              position = "center",
            },
          }
          table.insert(lines, line)
        end

        local output = {
          type = "group",
          val = lines,
          opts = { position = "center" },
        }

        return output
      end
      local if_nil = vim.F.if_nil
      local leader = "SPC"
      local function button(sc, txt, keybind, hl_opts, keybind_opts)
        local sc_ = sc:gsub("%s", ""):gsub(leader, "<leader>")

        local opts = {
          position = "center",
          hl = hl_opts,
          shortcut = sc,
          cursor = 56,
          width = 50,
          align_shortcut = "right",
          hl_shortcut = hl_opts,
        }
        if keybind then
          keybind_opts = if_nil(keybind_opts, {
            noremap = true,
            silent = true,
            nowait = true,
          })
          opts.keymap = { "n", sc_, keybind, keybind_opts }
        end

        local function on_press()
          local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
          vim.api.nvim_feedkeys(key, "t", false)
        end

        return {
          type = "button",
          val = txt,
          on_press = on_press,
          opts = opts,
        }
      end

      local Info = function()
        local datetime = os.date("󱪺 %A/%B/%d")
        local ver = vim.version()
        local info = "[ " .. datetime .. " -*- " .. "Vim version = " .. ver.major .. "." .. ver.minor .. " ]"
        return {
          type = "text",
          val = info,
          opts = { hl = "NvimPyYellow", position = "center" },
        }
      end

      local cdir = vim.fn.getcwd()

      local nvim_web_devicons = { enabled = true, highlight = true }

      local function get_extension(fn)
        local match = fn:match("^.+(%..+)$")
        local ext = ""
        if match ~= nil then
          ext = match:sub(2)
        end
        return ext
      end

      local function icon(fn)
        local nwd = require("nvim-web-devicons")
        local ext = get_extension(fn)
        return nwd.get_icon(fn, ext, { default = true })
      end

      local function file_button(fn, sc, short_fn, autocd)
        short_fn = short_fn or fn
        local ico_txt
        local fb_hl = {}

        if nvim_web_devicons.enabled then
          local ico, hl = icon(fn)
          local hl_option_type = type(nvim_web_devicons.highlight)
          if hl_option_type == "boolean" then
            if hl and nvim_web_devicons.highlight then
              table.insert(fb_hl, { hl, 0, #ico })
            end
          end
          if hl_option_type == "string" then
            table.insert(fb_hl, { nvim_web_devicons.highlight, 0, #ico })
          end
          ico_txt = ico .. "  "
        else
          ico_txt = ""
        end
        local cd_cmd = (autocd and " | cd %:p:h" or "")
        local file_button_el =
            button(sc, ico_txt .. short_fn, "<cmd>e " .. vim.fn.fnameescape(fn) .. cd_cmd .. " <CR>")
        local fn_start = short_fn:match(".*[/\\]")
        if fn_start ~= nil then
          table.insert(fb_hl, {
            "Comment",
            #ico_txt - 2,
            #fn_start + #ico_txt,
          })
        end
        file_button_el.opts.hl = fb_hl
        return file_button_el
      end

      local default_mru_ignore = { "gitcommit" }

      local mru_opts = {
        ignore = function(path, ext)
          return (string.find(path, "COMMIT_EDITMSG")) or (vim.tbl_contains(default_mru_ignore, ext))
        end,
        autocd = false,
      }

      --- @param start number
      --- @param cwd string? optional
      --- @param items_number number? optional number of items to generate, default = 10
      local function mru(start, cwd, items_number, opts)
        opts = opts or mru_opts
        items_number = if_nil(items_number, 5)

        local oldfiles = {}
        for _, v in pairs(vim.v.oldfiles) do
          if #oldfiles == items_number then
            break
          end
          local cwd_cond
          if not cwd then
            cwd_cond = true
          else
            cwd_cond = vim.startswith(v, cwd)
          end
          local ignore = (opts.ignore and opts.ignore(v, get_extension(v))) or false
          if (vim.fn.filereadable(v) == 1) and cwd_cond and not ignore then
            oldfiles[#oldfiles + 1] = v
          end
        end
        local target_width = 35

        local tbl = {}
        for i, fn in ipairs(oldfiles) do
          local short_fn
          if cwd then
            short_fn = vim.fn.fnamemodify(fn, ":.")
          else
            short_fn = vim.fn.fnamemodify(fn, ":~")
          end

          if #short_fn > target_width then
            short_fn = plenary_path.new(short_fn):shorten(1, { -2, -1 })
            if #short_fn > target_width then
              short_fn = plenary_path.new(short_fn):shorten(1, { -1 })
            end
          end

          local shortcut = tostring(i + start - 1)

          local file_button_el = file_button(fn, shortcut, short_fn, opts.autocd)
          tbl[i] = file_button_el
        end
        return { type = "group", val = tbl, opts = {} }
      end
      local section_mru = {
        type = "group",
        val = {
          { type = "padding", val = 2 },
          {
            type = "text",
            val = " Recent files",
            opts = {
              hl = "NvimPyGreen",
              shrink_margin = false,
              position = "center",
            },
          },
          { type = "padding", val = 1 },
          {
            type = "group",
            val = function()
              return { mru(0, cdir) }
            end,
            opts = { shrink_margin = false },
          },
        },
      }

      local butts = {
        type = "group",
        val = {
          { type = "padding", val = 2 },
          button("f", "  Find file", "<Cmd> Telescope find_files <CR>", "NvimPyBlue"),
          button("e", "  New file", "<Cmd> ene <BAR> startinsert <CR>", "NvimPyCyan"),
          button("r", "  Recently used files", "<Cmd> Telescope oldfiles <CR>", "NvimPyYellow"),
          button("t", "  Find text", "<Cmd> Telescope live_grep <CR>", "NvimPyGreen"),
          button("l", "  Lazy", "<Cmd> Lazy <CR>", "NvimPyPurple"),
          button("c", "  Configuration", "<Cmd> e $MYVIMRC <CR>", "NvimPyOrange"),
          button("q", "  Quit Neovim", "<Cmd> qa<CR>", "NvimPyRed"),
          { type = "padding", val = 2 },
        },
        position = "center",
      }
      Conf.layout[1] = { type = "padding", val = 2 }
      Conf.layout[2] = header_color()
      Conf.layout[3] = butts
      Conf.layout[4] = section_mru
      Conf.layout[5] = Info()
      return Conf
    end,
    config = function(_, Conf)
      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          once = true,
          pattern = "AlphaReady",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      require("alpha").setup(Conf)

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "LazyVimStarted",
        callback = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          Conf.layout[6] = {
            type = "text",
            val = "  NvimPy loaded "
                .. stats.loaded
                .. "/"
                .. stats.count
                .. " plugins in "
                .. ms
                .. "ms",
            opts = { hl = "NvimPyGreen", position = "center" },
          }
          pcall(vim.cmd.AlphaRedraw)
        end,
      })
    end,
  },
}
