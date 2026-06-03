local STS = require("SciVim.utils.treesitter")
return {

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = function()
      local TS = require("nvim-treesitter")
      if not TS.get_installed then
        vim.notify("Run :TSUpdate", vim.log.levels.ERROR, { title = "TreeSitter" })
        return
      end
      STS.build(function()
        TS.update(nil, { summary = true })
      end)
    end,
    opts_extend = { "ensure_installed" },
    opts = {
      indent = { enable = true },
      highlight = { enable = true },
      folds = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "latex",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "toml",
        "typst",
        "vim",
        "vimdoc",
        "xml",
        "yaml",

      }
    },
    config = function(_, opts)
      local TS = require("nvim-treesitter")

      setmetatable(require("nvim-treesitter.install"), {
        __newindex = function(_, k)
          if k == "compilers" then
            vim.schedule(function()
              vim.notify("Check Complires for TreeSitter", vim.log.levels.ERROR, { title = "TreeSitter" })
            end)
          end
        end
      })

      if not TS.get_installed then
        return vim.notify("Update treesitter by package manager", vim.log.levels.ERROR)
      elseif type(opts.ensure_installed) ~= "table" then
        return vim.notify("`ensure_installed` must be a table", vim.log.levels.ERROR)
      end

      TS.setup(opts)
      STS.get_installed(true)

      local install = vim.tbl_filter(function(lang)
        return not STS.have(lang)
      end, opts.ensure_installed or {})
      if #install > 0 then
        STS.build(function()
          TS.install(install, { summary = true }):await(function()
            STS.get_installed(true)
          end)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("SciVimTreesitter", { clear = true }),
        callback = function(ev)
          local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
          if not STS.have(ft) then
            return
          end
          local function enabled(feat, query)
            local f = opts[feat] or {}
            return f.enable ~= false
                and not (type(f.disable) == "table" and vim.tbl_contains(f.disable, lang))
                and STS.have(ft, query)
          end
          if enabled("highlight", "highlights") then
            pcall(vim.treesitter.start, ev)
          end
        end
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    enabled = true,
    keys = function()
      local moves = {
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = {
          ["[f"] = "@function.outer",
          ["[c"] = "@class.outer",
          ["[a"] = "@parameter.inner",
        },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
      }
      local ret = {} ---@type LazyKeysSpec[]
      for method, keymaps in pairs(moves) do
        for key, query in pairs(keymaps) do
          local desc = query:gsub("@", ""):gsub("%..*", "")
          desc = desc:sub(1, 1):upper() .. desc:sub(2)
          desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
          desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
          ret[#ret + 1] = {
            key,
            function()
              -- don't use treesitter if in diff mode and the key is one of the c/C keys
              if vim.wo.diff and key:find("[cC]") then
                return vim.cmd("normal! " .. key)
              end
              require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
            end,
            desc = desc,
            mode = { "n", "x", "o" },
            silent = true,
          }
        end
      end
      return ret
    end,
    config = function()
      -- If treesitter is already loaded, we need to run config again for textobjects
      if require("SciVim.utils").is_loaded("nvim-treesitter") then
        local opts = require("SciVim.utils").opts("nvim-treesitter")
        require("nvim-treesitter").setup({ textobjects = opts.textobjects })
      end
    end,
  },
}
