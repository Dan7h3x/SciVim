local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local d = ls.dynamic_node
local r = ls.restore_node
local function node_with_virtual_text(pos, node, text)
  local nodes
  if node.type == types.textNode then
    node.pos = 2
    nodes = { i(1), node }
  else
    node.pos = 1
    nodes = { node }
  end
  return sn(pos, nodes, {
    node_ext_opts = {
      active = {
        -- override highlight here ("GruvboxOrange").
        virt_text = { { text, "GruvboxOrange" } },
      },
    },
  })
end

local function nodes_with_virtual_text(nodes, opts)
  if opts == nil then
    opts = {}
  end
  local new_nodes = {}
  for pos, node in ipairs(nodes) do
    if opts.texts[pos] ~= nil then
      node = node_with_virtual_text(pos, node, opts.texts[pos])
    end
    table.insert(new_nodes, node)
  end
  return new_nodes
end

local function choice_text_node(pos, choices, opts)
  choices = nodes_with_virtual_text(choices, opts)
  return c(pos, choices, opts)
end

local ct = choice_text_node

ls.add_snippets("python", {
  s(
    "d",
    fmt(
      [[
		def {func}({args}){ret}:
			{doc}{body}
	]],
      {
        func = i(1),
        args = i(2),
        ret = c(3, {
          t(""),
          sn(nil, {
            t(" -> "),
            i(1),
          }),
        }),
        doc = isn(4, {
          ct(1, {
            t(""),
            -- NOTE we need to surround the `fmt` with `sn` to make this work
            sn(
              1,
              fmt(
                [[
			"""{desc}"""

			]],
                { desc = i(1) }
              )
            ),
            sn(
              2,
              fmt(
                [[
			"""{desc}

			Args:
			{args}

			Returns:
			{returns}
			"""

			]],
                {
                  desc = i(1),
                  args = i(2), -- TODO should read from the args in the function
                  returns = i(3),
                }
              )
            ),
          }, {
            texts = {
              "(no docstring)",
              "(single line docstring)",
              "(full docstring)",
            },
          }),
        }, "$PARENT_INDENT\t"),
        body = i(0),
      }
    )
  ),
})

local function py_init()
  return sn(
    nil,
    c(1, {
      t(""),
      sn(1, {
        t(", "),
        i(1),
        d(2, py_init),
      }),
    })
  )
end

-- splits the string of the comma separated argument list into the arguments
-- and returns the text-/insert- or restore-nodes
local function to_init_assign(args)
  local tab = {}
  local a = args[1][1]
  if #a == 0 then
    table.insert(tab, t({ "", "\tpass" }))
  else
    local cnt = 1
    for e in string.gmatch(a, " ?([^,]*) ?") do
      if #e > 0 then
        table.insert(tab, t({ "", "\tself." }))
        -- use a restore-node to be able to keep the possibly changed attribute name
        -- (otherwise this function would always restore the default, even if the user
        -- changed the name)
        table.insert(tab, r(cnt, tostring(cnt), i(nil, e)))
        table.insert(tab, t(" = "))
        table.insert(tab, t(e))
        cnt = cnt + 1
      end
    end
  end
  return sn(nil, tab)
end

-- create the actual snippet
ls.add_snippets(
  "python",
  { s(
    "pyinit",
    fmt([[def __init__(self{}):{}]], {
      d(1, py_init),
      d(2, to_init_assign, { 1 }),
    })
  ) }
)

-- dynamic node generator
local generate_matchcase_dynamic = function(args, snip)
  if not snip.num_cases then
    snip.num_cases = tonumber(snip.captures[1]) or 1
  end
  local nodes = {}
  local ins_idx = 1
  for j = 1, snip.num_cases do
    vim.list_extend(
      nodes,
      fmta(
        [[
        case <>:
            <>
        ]],
        { r(ins_idx, "var" .. j, i(1)), r(ins_idx + 1, "next" .. j, i(0)) }
      )
    )
    table.insert(nodes, t({ "", "" }))
    ins_idx = ins_idx + 2
  end
  table.remove(nodes, #nodes) -- removes the extra line break
  return isn(nil, nodes, "\t")
end

-- snippet
ls.add_snippets("python", {
  s(
    { trig = "mc(%d*)", name = "match case", dscr = "match n cases", regTrig = true, hidden = true },
    fmta(
      [[
    match <>:
        <>
        <>
    ]],
      {
        i(1),
        d(2, generate_matchcase_dynamic, {}, {
          user_args = {
            function(snip)
              snip.num_cases = snip.num_cases + 1
            end,
            function(snip)
              snip.num_cases = math.max(snip.num_cases - 1, 1)
            end, -- don't drop below 1 case, probably can be modified but it seems reasonable to me :shrug:
          },
        }),
        c(3, { t(""), isn(
          nil,
          fmta(
            [[
    case _:
        <>
    ]],
            { i(1, "pass") }
          ),
          "\t"
        ) }),
      }
    )
  ),
})
