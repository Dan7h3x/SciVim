-- lua/zk/graph.lua
-- Knowledge graph: generates a self-contained interactive HTML file
-- and opens it in the default browser, OR renders a simplified ASCII
-- graph in a Neovim floating window for terminal-only environments.

local M = {}
local index = require("zk.index")

local function cfg() return require("zk").config end

-- ─── Data collection ─────────────────────────────────────────────────────────

---@return { nodes: table[], links: table[] }
local function build_graph_data()
  local notes = index.all()

  -- assign stable numeric ids for d3
  local id_to_num = {}
  local nodes = {}
  for i, note in ipairs(notes) do
    id_to_num[note.id] = i - 1
    -- also map stem
    local stem = vim.fn.fnamemodify(note.path, ":t:r")
    id_to_num[stem] = i - 1
    nodes[#nodes + 1] = {
      id    = i - 1,
      name  = note.id,
      title = note.title,
      tags  = note.tags,
      date  = note.date,
      path  = note.path,
    }
  end

  local links = {}
  local seen_links = {}
  for _, note in ipairs(notes) do
    local src = id_to_num[note.id]
    if src then
      for _, ref in ipairs(note.links) do
        local dst = id_to_num[ref]
        if dst and dst ~= src then
          local key = math.min(src, dst) .. "-" .. math.max(src, dst)
          if not seen_links[key] then
            seen_links[key] = true
            links[#links + 1] = { source = src, target = dst }
          end
        end
      end
    end
  end

  return { nodes = nodes, links = links }
end

-- ─── HTML generation ─────────────────────────────────────────────────────────

local function json_encode(val)
  -- Use Neovim's built-in JSON encoder (available since 0.5)
  return vim.fn.json_encode(val)
end

local function generate_html(data)
  local nodes_json = json_encode(data.nodes)
  local links_json = json_encode(data.links)
  local title = "ZK Graph — " .. cfg().dir

  return string.format([[<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>%s</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg:       #0d0f14;
    --surface:  #141720;
    --border:   #1e2230;
    --text:     #c8cdd8;
    --muted:    #5a6070;
    --accent:   #7aa2f7;
    --accent2:  #bb9af7;
    --green:    #9ece6a;
    --orange:   #e0af68;
    --red:      #f7768e;
    --node-r:   6;
  }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'JetBrains Mono', 'Cascadia Code', 'Fira Code', monospace;
    font-size: 13px;
    overflow: hidden;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }

  /* ── Toolbar ── */
  #toolbar {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 8px 16px;
    background: var(--surface);
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
    z-index: 10;
  }

  #toolbar h1 {
    font-size: 12px;
    font-weight: 600;
    color: var(--accent);
    letter-spacing: .06em;
    text-transform: uppercase;
    margin-right: auto;
  }

  .tb-btn {
    background: var(--border);
    border: 1px solid var(--border);
    color: var(--text);
    padding: 4px 10px;
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
    font-size: 11px;
    transition: background .15s;
  }
  .tb-btn:hover { background: var(--accent); color: var(--bg); }

  #search-input {
    background: var(--bg);
    border: 1px solid var(--border);
    color: var(--text);
    padding: 4px 10px;
    border-radius: 4px;
    font-family: inherit;
    font-size: 12px;
    width: 200px;
    outline: none;
  }
  #search-input:focus { border-color: var(--accent); }

  #stats {
    font-size: 11px;
    color: var(--muted);
  }

  /* ── Main area ── */
  #main {
    flex: 1;
    display: flex;
    overflow: hidden;
  }

  #graph-container {
    flex: 1;
    position: relative;
    overflow: hidden;
  }

  svg {
    width: 100%%;
    height: 100%%;
    cursor: grab;
  }
  svg:active { cursor: grabbing; }

  .link {
    stroke: var(--border);
    stroke-width: 1.2;
    stroke-opacity: .6;
    transition: stroke .2s;
  }
  .link.highlighted { stroke: var(--accent); stroke-opacity: .9; stroke-width: 2; }

  .node circle {
    fill: var(--surface);
    stroke: var(--accent);
    stroke-width: 1.5;
    cursor: pointer;
    transition: r .15s, stroke .15s;
  }
  .node.orphan circle   { stroke: var(--muted); }
  .node.hub circle      { stroke: var(--accent2); fill: #1a1530; }
  .node.daily circle    { stroke: var(--green); }
  .node.selected circle { stroke: var(--orange); stroke-width: 2.5; }
  .node.dimmed circle   { opacity: .2; }
  .node.dimmed text     { opacity: .1; }

  .node text {
    fill: var(--muted);
    font-size: 10px;
    pointer-events: none;
    user-select: none;
    transition: opacity .15s;
  }
  .node:hover text { fill: var(--text); }

  /* ── Sidebar ── */
  #sidebar {
    width: 280px;
    background: var(--surface);
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    flex-shrink: 0;
    overflow: hidden;
    transition: width .2s;
  }
  #sidebar.hidden { width: 0; }

  #sidebar-header {
    padding: 12px 16px 8px;
    border-bottom: 1px solid var(--border);
    font-size: 11px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: .06em;
  }

  #sidebar-content {
    padding: 12px 16px;
    overflow-y: auto;
    flex: 1;
  }

  #note-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--accent);
    margin-bottom: 8px;
    line-height: 1.3;
  }

  #note-meta {
    font-size: 11px;
    color: var(--muted);
    margin-bottom: 12px;
  }

  .tag-badge {
    display: inline-block;
    background: var(--border);
    color: var(--accent2);
    border-radius: 3px;
    padding: 1px 6px;
    font-size: 10px;
    margin: 2px 2px 2px 0;
  }

  .link-section { margin-top: 12px; }
  .link-section h4 {
    font-size: 10px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: .06em;
    margin-bottom: 6px;
  }

  .note-link {
    display: block;
    padding: 4px 0;
    color: var(--text);
    text-decoration: none;
    font-size: 12px;
    cursor: pointer;
    transition: color .1s;
  }
  .note-link:hover { color: var(--accent); }
  .note-link::before { content: '→ '; color: var(--muted); }

  /* ── Minimap ── */
  #minimap {
    position: absolute;
    bottom: 12px;
    right: 12px;
    width: 140px;
    height: 90px;
    background: rgba(20,23,32,.85);
    border: 1px solid var(--border);
    border-radius: 4px;
    overflow: hidden;
    pointer-events: none;
  }

  /* ── Tooltip ── */
  #tooltip {
    position: fixed;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 6px 10px;
    font-size: 11px;
    pointer-events: none;
    opacity: 0;
    transition: opacity .1s;
    z-index: 100;
    max-width: 240px;
  }

  /* ── Legend ── */
  #legend {
    position: absolute;
    bottom: 12px;
    left: 12px;
    font-size: 10px;
    color: var(--muted);
    line-height: 1.8;
  }
  .leg { display: flex; align-items: center; gap: 6px; }
  .leg-dot {
    width: 10px; height: 10px; border-radius: 50%;
    border: 1.5px solid var(--muted); background: var(--surface);
    flex-shrink: 0;
  }
  .leg-dot.hub   { border-color: var(--accent2); background: #1a1530; }
  .leg-dot.daily { border-color: var(--green); }
  .leg-dot.acc   { border-color: var(--accent); }

  /* scrollbar */
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: var(--surface); }
  ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }
</style>
</head>
<body>

<div id="toolbar">
  <h1>⬡ ZK Graph</h1>
  <input id="search-input" placeholder="Search notes…" autocomplete="off">
  <button class="tb-btn" id="btn-reset">Reset zoom</button>
  <button class="tb-btn" id="btn-sidebar">Panel</button>
  <button class="tb-btn" id="btn-links">Links: all</button>
  <span id="stats"></span>
</div>

<div id="main">
  <div id="graph-container">
    <svg id="svg"></svg>
    <div id="minimap"><svg id="minimap-svg"></svg></div>
    <div id="legend">
      <div class="leg"><div class="leg-dot acc"></div> Note</div>
      <div class="leg"><div class="leg-dot hub"></div> Hub (4+ links)</div>
      <div class="leg"><div class="leg-dot daily"></div> Daily</div>
      <div class="leg"><div class="leg-dot"></div> Orphan</div>
    </div>
  </div>
  <div id="sidebar">
    <div id="sidebar-header">Note details</div>
    <div id="sidebar-content">
      <div style="color:var(--muted);font-size:12px">Click a node to inspect it.</div>
    </div>
  </div>
</div>

<div id="tooltip"></div>

<script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
<script>
const RAW_NODES = %s;
const RAW_LINKS = %s;

// ── Degree map ────────────────────────────────────────────────────────────────
const degree = {};
RAW_NODES.forEach(n => degree[n.id] = 0);
RAW_LINKS.forEach(l => {
  degree[l.source] = (degree[l.source] || 0) + 1;
  degree[l.target] = (degree[l.target] || 0) + 1;
});

const HUB_THRESHOLD = 4;

// ── SVG setup ─────────────────────────────────────────────────────────────────
const svg = d3.select("#svg");
const container = document.getElementById("graph-container");

let width  = container.clientWidth;
let height = container.clientHeight;

const g = svg.append("g");

// zoom
const zoom = d3.zoom()
  .scaleExtent([0.05, 8])
  .on("zoom", e => { g.attr("transform", e.transform); updateMinimap(); });
svg.call(zoom);

// ── Simulation ────────────────────────────────────────────────────────────────
const simulation = d3.forceSimulation(RAW_NODES)
  .force("link", d3.forceLink(RAW_LINKS).id(d => d.id).distance(d => {
    const deg = Math.max(degree[d.source.id] || 0, degree[d.target.id] || 0);
    return 60 + deg * 8;
  }))
  .force("charge", d3.forceManyBody().strength(d => {
    return degree[d.id] > HUB_THRESHOLD ? -300 : -120;
  }))
  .force("center", d3.forceCenter(width / 2, height / 2))
  .force("collision", d3.forceCollide().radius(d => nodeRadius(d) + 4))
  .alphaDecay(0.025);

function nodeRadius(d) {
  const deg = degree[d.id] || 0;
  return 5 + Math.sqrt(deg) * 2.5;
}

// ── Render links ──────────────────────────────────────────────────────────────
const linkSel = g.append("g")
  .attr("class", "links")
  .selectAll("line")
  .data(RAW_LINKS)
  .join("line")
  .attr("class", "link");

// ── Render nodes ──────────────────────────────────────────────────────────────
const nodeSel = g.append("g")
  .attr("class", "nodes")
  .selectAll(".node")
  .data(RAW_NODES)
  .join("g")
  .attr("class", d => {
    const cls = ["node"];
    if ((degree[d.id] || 0) === 0) cls.push("orphan");
    if ((degree[d.id] || 0) >= HUB_THRESHOLD) cls.push("hub");
    if (d.name.match(/^\d{4}-\d{2}-\d{2}/)) cls.push("daily");
    return cls.join(" ");
  })
  .call(d3.drag()
    .on("start", dragStart)
    .on("drag",  dragged)
    .on("end",   dragEnd))
  .on("click",      onNodeClick)
  .on("mouseover",  onNodeOver)
  .on("mouseout",   onNodeOut);

nodeSel.append("circle")
  .attr("r", nodeRadius);

nodeSel.append("text")
  .attr("dy", d => nodeRadius(d) + 11)
  .attr("text-anchor", "middle")
  .text(d => d.title.length > 22 ? d.title.slice(0, 20) + "…" : d.title);

// ── Tick ─────────────────────────────────────────────────────────────────────
simulation.on("tick", () => {
  linkSel
    .attr("x1", d => d.source.x)
    .attr("y1", d => d.source.y)
    .attr("x2", d => d.target.x)
    .attr("y2", d => d.target.y);

  nodeSel.attr("transform", d => `translate(${d.x},${d.y})`);
  updateMinimap();
});

// ── Drag ─────────────────────────────────────────────────────────────────────
function dragStart(event, d) {
  if (!event.active) simulation.alphaTarget(0.3).restart();
  d.fx = d.x; d.fy = d.y;
}
function dragged(event, d) { d.fx = event.x; d.fy = event.y; }
function dragEnd(event, d) {
  if (!event.active) simulation.alphaTarget(0);
  d.fx = null; d.fy = null;
}

// ── Selection & highlight ─────────────────────────────────────────────────────
let selectedNode = null;
let linkFilter   = "all"; // "all" | "direct"

function highlightNeighbors(d) {
  if (!d) {
    nodeSel.classed("dimmed", false).classed("selected", false);
    linkSel.classed("highlighted", false).classed("dimmed", false);
    return;
  }

  const neighborIds = new Set([d.id]);
  const connectedLinks = new Set();

  RAW_LINKS.forEach((l, i) => {
    const sid = typeof l.source === "object" ? l.source.id : l.source;
    const tid = typeof l.target === "object" ? l.target.id : l.target;
    if (sid === d.id || tid === d.id) {
      neighborIds.add(sid);
      neighborIds.add(tid);
      connectedLinks.add(i);
    }
  });

  nodeSel
    .classed("dimmed",   n => !neighborIds.has(n.id))
    .classed("selected", n => n.id === d.id);

  linkSel
    .classed("highlighted", (_, i) => connectedLinks.has(i))
    .classed("dimmed",      (_, i) => !connectedLinks.has(i));
}

function onNodeClick(event, d) {
  event.stopPropagation();
  if (selectedNode === d) {
    selectedNode = null;
    highlightNeighbors(null);
    renderSidebar(null);
  } else {
    selectedNode = d;
    highlightNeighbors(d);
    renderSidebar(d);
  }
}

svg.on("click", () => {
  selectedNode = null;
  highlightNeighbors(null);
  renderSidebar(null);
});

// ── Tooltip ───────────────────────────────────────────────────────────────────
const tooltip = document.getElementById("tooltip");

function onNodeOver(event, d) {
  const deg = degree[d.id] || 0;
  tooltip.innerHTML = `<strong>${d.title}</strong><br>${d.date || ""}  •  ${deg} link${deg !== 1 ? "s" : ""}`;
  tooltip.style.opacity = "1";
}
function onNodeOut() { tooltip.style.opacity = "0"; }
document.addEventListener("mousemove", e => {
  tooltip.style.left = (e.clientX + 14) + "px";
  tooltip.style.top  = (e.clientY - 8) + "px";
});

// ── Sidebar ───────────────────────────────────────────────────────────────────
function renderSidebar(d) {
  const content = document.getElementById("sidebar-content");
  if (!d) {
    content.innerHTML = '<div style="color:var(--muted);font-size:12px">Click a node to inspect it.</div>';
    return;
  }

  // outgoing links
  const outIds = new Set();
  RAW_LINKS.forEach(l => {
    const sid = typeof l.source === "object" ? l.source.id : l.source;
    const tid = typeof l.target === "object" ? l.target.id : l.target;
    if (sid === d.id) outIds.add(tid);
    if (tid === d.id) outIds.add(sid);
  });

  const neighbors = RAW_NODES.filter(n => outIds.has(n.id));

  const tags = d.tags && d.tags.length
    ? d.tags.map(t => `<span class="tag-badge">#${t}</span>`).join("")
    : '<span style="color:var(--muted)">no tags</span>';

  const linksHtml = neighbors.length
    ? neighbors.map(n =>
        `<span class="note-link" data-id="${n.id}">${n.title}</span>`
      ).join("")
    : '<span style="color:var(--muted)">none</span>';

  content.innerHTML = `
    <div id="note-title">${d.title}</div>
    <div id="note-meta">
      <div>${d.date || "no date"}</div>
      <div style="margin-top:4px">${d.path}</div>
    </div>
    <div style="margin-bottom:8px">${tags}</div>
    <div class="link-section">
      <h4>Connections (${neighbors.length})</h4>
      ${linksHtml}
    </div>
  `;

  // clicking a neighbor navigates
  content.querySelectorAll(".note-link").forEach(el => {
    el.addEventListener("click", () => {
      const id = parseInt(el.dataset.id);
      const node = RAW_NODES[id];
      if (node) {
        selectedNode = node;
        highlightNeighbors(node);
        renderSidebar(node);
        // pan to it
        const t = d3.zoomTransform(svg.node());
        const tx = width / 2 - t.k * node.x;
        const ty = height / 2 - t.k * node.y;
        svg.transition().duration(400)
          .call(zoom.transform, d3.zoomIdentity.translate(tx, ty).scale(t.k));
      }
    });
  });
}

// ── Minimap ───────────────────────────────────────────────────────────────────
const mmSvg = d3.select("#minimap-svg")
  .attr("width", 140).attr("height", 90);

const mmG = mmSvg.append("g");

mmG.append("g").attr("class", "mm-links")
  .selectAll("line").data(RAW_LINKS).join("line")
  .attr("stroke", "#1e2230").attr("stroke-width", .5);

const mmNodes = mmG.append("g").attr("class", "mm-nodes")
  .selectAll("circle").data(RAW_NODES).join("circle")
  .attr("r", 2).attr("fill", "#7aa2f7").attr("opacity", .5);

function updateMinimap() {
  const xs = RAW_NODES.map(d => d.x || 0);
  const ys = RAW_NODES.map(d => d.y || 0);
  const minX = Math.min(...xs), maxX = Math.max(...xs);
  const minY = Math.min(...ys), maxY = Math.max(...ys);
  const rangeX = maxX - minX || 1;
  const rangeY = maxY - minY || 1;

  const scaleX = d => ((d.x || 0) - minX) / rangeX * 136 + 2;
  const scaleY = d => ((d.y || 0) - minY) / rangeY * 86 + 2;

  mmG.selectAll(".mm-links line")
    .attr("x1", d => scaleX(typeof d.source === "object" ? d.source : RAW_NODES[d.source]))
    .attr("y1", d => scaleY(typeof d.source === "object" ? d.source : RAW_NODES[d.source]))
    .attr("x2", d => scaleX(typeof d.target === "object" ? d.target : RAW_NODES[d.target]))
    .attr("y2", d => scaleY(typeof d.target === "object" ? d.target : RAW_NODES[d.target]));

  mmNodes.attr("cx", scaleX).attr("cy", scaleY);
}

// ── Search ────────────────────────────────────────────────────────────────────
const searchInput = document.getElementById("search-input");
searchInput.addEventListener("input", () => {
  const q = searchInput.value.toLowerCase().trim();
  if (!q) { highlightNeighbors(null); return; }

  const matches = RAW_NODES.filter(n =>
    n.title.toLowerCase().includes(q) ||
    n.name.toLowerCase().includes(q)  ||
    (n.tags && n.tags.some(t => t.toLowerCase().includes(q)))
  );

  if (matches.length === 0) return;

  // dim non-matches
  const matchIds = new Set(matches.map(n => n.id));
  nodeSel.classed("dimmed", n => !matchIds.has(n.id));
  linkSel.classed("dimmed", true).classed("highlighted", false);

  // pan to first match
  const first = matches[0];
  const t = d3.zoomTransform(svg.node());
  svg.transition().duration(500)
    .call(zoom.transform,
      d3.zoomIdentity
        .translate(width / 2 - t.k * (first.x || 0), height / 2 - t.k * (first.y || 0))
        .scale(t.k));
});

// ── Toolbar buttons ───────────────────────────────────────────────────────────
document.getElementById("btn-reset").addEventListener("click", () => {
  svg.transition().duration(500).call(zoom.transform, d3.zoomIdentity
    .translate(width / 2, height / 2).scale(1));
});

document.getElementById("btn-sidebar").addEventListener("click", () => {
  document.getElementById("sidebar").classList.toggle("hidden");
  width = container.clientWidth;
  simulation.force("center", d3.forceCenter(width / 2, height / 2));
});

const btnLinks = document.getElementById("btn-links");
btnLinks.addEventListener("click", () => {
  linkFilter = linkFilter === "all" ? "orphan" : "all";
  btnLinks.textContent = linkFilter === "all" ? "Links: all" : "Links: hide orphans";
  nodeSel.classed("dimmed", d => linkFilter === "orphan" && (degree[d.id] || 0) === 0);
});

// ── Stats ─────────────────────────────────────────────────────────────────────
document.getElementById("stats").textContent =
  `${RAW_NODES.length} notes  •  ${RAW_LINKS.length} links`;

// ── Keyboard ──────────────────────────────────────────────────────────────────
document.addEventListener("keydown", e => {
  if (e.key === "/" || (e.key === "f" && !e.ctrlKey)) {
    e.preventDefault();
    searchInput.focus();
    searchInput.select();
  }
  if (e.key === "Escape") {
    searchInput.value = "";
    searchInput.blur();
    selectedNode = null;
    highlightNeighbors(null);
  }
  if (e.key === "0") {
    svg.transition().duration(400).call(zoom.transform,
      d3.zoomIdentity.translate(width / 2, height / 2).scale(1));
  }
});

// ── Resize ────────────────────────────────────────────────────────────────────
window.addEventListener("resize", () => {
  width  = container.clientWidth;
  height = container.clientHeight;
  simulation.force("center", d3.forceCenter(width / 2, height / 2));
  simulation.alpha(0.1).restart();
});

// initial zoom
svg.call(zoom.transform, d3.zoomIdentity.translate(width / 2, height / 2).scale(1));
</script>
</body>
</html>]], title, nodes_json, links_json)
end

-- ─── Float ASCII graph ────────────────────────────────────────────────────────

--- Simple text graph in a Neovim float (fallback / quick overview)
local function ascii_graph()
  local notes = index.all()
  local lines = {
    "  ZK Graph — " .. cfg().dir,
    string.rep("─", 60),
    "",
  }

  -- sort by degree desc
  local idx = require("zk.index")
  local by_deg = {}
  for _, note in ipairs(notes) do
    local bl = idx.backlinks(note.id)
    by_deg[#by_deg + 1] = { note = note, out = #note.links, in_ = #bl }
  end
  table.sort(by_deg, function(a, b) return (a.out + a.in_) > (b.out + b.in_) end)

  for _, row in ipairs(by_deg) do
    local note        = row.note
    local bar         = string.rep("█", math.min(row.out + row.in_, 20))
    lines[#lines + 1] = string.format(
      "  %-30s %s (%d↑ %d↓)",
      note.title:sub(1, 30), bar, row.out, row.in_
    )
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = string.rep("─", 60)
  lines[#lines + 1] = "  [q] close   [<CR>] open note"

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype   = "zk-graph"

  local win_w            = math.min(70, vim.o.columns - 4)
  local win_h            = math.min(#lines + 2, vim.o.lines - 4)
  local win              = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = win_w,
    height    = win_h,
    row       = math.floor((vim.o.lines - win_h) / 2),
    col       = math.floor((vim.o.columns - win_w) / 2),
    style     = "minimal",
    border    = "rounded",
    title     = " ZK Graph ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,CursorLine:Visual")

  -- Keymaps
  local function km(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true }) end
  km("q", function() vim.api.nvim_win_close(win, true) end)
  km("<Esc>", function() vim.api.nvim_win_close(win, true) end)
  km("<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(win)[1]
    local entry  = by_deg[cursor - 3] -- offset for header lines
    if entry then
      vim.api.nvim_win_close(win, true)
      vim.cmd("edit " .. vim.fn.fnameescape(entry.note.path))
    end
  end)
end

-- ─── Public API ──────────────────────────────────────────────────────────────

--- Open the graph view
function M.open()
  index.ensure()

  local viewer = cfg().graph_viewer
  if viewer == "float" then
    ascii_graph()
    return
  end

  -- Generate HTML and open in browser
  local data = build_graph_data()

  if #data.nodes == 0 then
    vim.notify("[ZK] No notes to graph", vim.log.levels.WARN)
    return
  end

  local html     = generate_html(data)
  local tmp_path = vim.fn.tempname() .. ".html"
  local fd       = io.open(tmp_path, "w")
  if not fd then
    vim.notify("[ZK] Could not write graph HTML", vim.log.levels.ERROR)
    return
  end
  fd:write(html)
  fd:close()

  -- Platform-aware open
  local open_cmd
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    open_cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    open_cmd = "start"
  end

  if open_cmd then
    vim.fn.jobstart({ open_cmd, tmp_path }, { detach = true })
    vim.notify(
      string.format("[ZK] Graph: %d notes, %d links → browser", #data.nodes, #data.links),
      vim.log.levels.INFO
    )
  else
    vim.notify("[ZK] Graph saved to: " .. tmp_path, vim.log.levels.INFO)
  end
end

--- Return graph data for external use (e.g. Lua scripts, tests)
function M.data()
  index.ensure()
  return build_graph_data()
end

return M
