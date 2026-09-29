local util = require('helpdocs.util')
local html = require('helpdocs.parser.html')
local M = {}

local function text_of(node)
  if node.text then return node.text end
  local t = {}
  for _, c in ipairs(node.children or {}) do t[#t + 1] = text_of(c) end
  return table.concat(t)
end

local function clean_text(s)
  return vim.trim((s or ''):gsub('%s+', ' '))
end

local function inline(nodes, ctx)
  local out = {}
  for _, n in ipairs(nodes or {}) do
    if n.text then
      out[#out + 1] = n.text:gsub('%s+', ' ')
    elseif n.tag == 'code' then
      out[#out + 1] = '`' .. clean_text(text_of(n)) .. '`'
    elseif n.tag == 'a' then
      local label = clean_text(inline(n.children, ctx))
      local href = n.attrs and n.attrs.href or ''
      local tag = ctx.href_tags[href] or (href:match('^#(.+)') and ctx.anchor_tags[href:match('^#(.+)')])
      out[#out + 1] = tag and ('|' .. tag .. '|') or label
    elseif n.tag == 'strong' or n.tag == 'b' then
      out[#out + 1] = clean_text(inline(n.children, ctx))
    elseif n.tag == 'em' or n.tag == 'i' then
      out[#out + 1] = clean_text(inline(n.children, ctx))
    elseif n.tag ~= 'svg' and n.tag ~= 'img' then
      out[#out + 1] = inline(n.children, ctx)
    end
  end
  return table.concat(out)
end

local function add_para(lines, s, prefix)
  s = clean_text(s)
  if s == '' then return end
  for _, line in ipairs(util.wrap((prefix or '') .. s, 78)) do lines[#lines + 1] = line end
  lines[#lines + 1] = ''
end

local function add_code(lines, s)
  s = html.decode(s or ''):gsub('^%s*\n', ''):gsub('%s+$', '')
  lines[#lines + 1] = 'Example: >'
  lines[#lines + 1] = ''
  for line in (s .. '\n'):gmatch('(.-)\n') do lines[#lines + 1] = '    ' .. line end
  lines[#lines + 1] = '<'
  lines[#lines + 1] = ''
end

local function walk(node, ctx, lines, depth)
  if node.text then return end
  local tag = node.tag
  if tag == 'h1' or tag == 'h2' or tag == 'h3' then
    local title = clean_text(inline(node.children, ctx))
    local anchor = node.attrs and node.attrs.id
    local tagname = anchor and ctx.anchor_tags[anchor]
    lines[#lines + 1] = string.rep('=', tag == 'h1' and 78 or 40)
    lines[#lines + 1] = tagname and (title .. string.rep(' ', math.max(1, 60 - #title)) .. '*' .. tagname .. '*') or title
    lines[#lines + 1] = ''
  elseif tag == 'p' then
    add_para(lines, inline(node.children, ctx))
  elseif tag == 'pre' then
    add_code(lines, text_of(node))
  elseif tag == 'blockquote' then
    add_para(lines, inline(node.children, ctx), '    ')
  elseif tag == 'ul' or tag == 'ol' then
    local i = 1
    for _, li in ipairs(node.children or {}) do
      if li.tag == 'li' then
        add_para(lines, inline(li.children, ctx), tag == 'ol' and (i .. '. ') or '- ')
        i = i + 1
      end
    end
  elseif tag == 'table' then
    for _, tr in ipairs(node.children or {}) do
      if tr.tag == 'tr' or tr.tag == 'thead' or tr.tag == 'tbody' then walk(tr, ctx, lines, depth) end
    end
    lines[#lines + 1] = ''
  elseif tag == 'tr' then
    local cells = {}
    for _, c in ipairs(node.children or {}) do if c.tag == 'td' or c.tag == 'th' then cells[#cells + 1] = clean_text(inline(c.children, ctx)) end end
    if #cells > 0 then lines[#lines + 1] = table.concat(cells, ' | ') end
  elseif tag == 'code' then
    add_para(lines, inline({ node }, ctx))
  else
    local has_block = false
    for _, c in ipairs(node.children or {}) do
      if c.tag and c.tag ~= 'span' and c.tag ~= 'code' and c.tag ~= 'a' and c.tag ~= 'strong' and c.tag ~= 'em' and c.tag ~= 'b' and c.tag ~= 'i' then
        has_block = true
        break
      end
    end
    if tag ~= 'root' and not has_block then
      add_para(lines, inline(node.children, ctx))
      return
    end
    for _, c in ipairs(node.children or {}) do walk(c, ctx, lines, depth + 1) end
  end
end

local function tag_for(ns, name)
  return ns .. '-' .. util.slug(name):gsub('^' .. ns .. '%-', '')
end

function M.render(doc)
  local ns = doc.namespace
  local entries = doc.entries or {}
  local href_tags, used = {}, {}
  used[ns] = true
  for _, e in ipairs(entries) do
    local tag = tag_for(ns, e.name)
    local base, n = tag, 2
    while used[tag] do tag = base .. '-' .. n; n = n + 1 end
    used[tag] = true
    e.tag = tag
    href_tags[e.path] = tag
    href_tags['/' .. e.path] = tag
    href_tags[e.path .. '.html'] = tag
    href_tags['../' .. e.path] = tag
  end

  local lines = { ns .. '.txt\t' .. doc.name .. ' documentation from DevDocs', '', string.rep('=', 78), doc.name .. string.rep(' ', math.max(1, 60 - #doc.name)) .. '*' .. ns .. '*', '' }
  add_para(lines, ('Generated from DevDocs%s.'):format(doc.release and (' (' .. doc.release .. ')') or ''))

  for _, e in ipairs(entries) do
    local body = doc.pages[e.path]
    if body then
      lines[#lines + 1] = string.rep('=', 78)
      lines[#lines + 1] = e.name .. string.rep(' ', math.max(1, 60 - #e.name)) .. '*' .. e.tag .. '*'
      if e.type then lines[#lines + 1] = e.type; lines[#lines + 1] = '' end
      local root = html.parse(body)
      local ctx = { href_tags = href_tags, anchor_tags = {} }
      for _, n in ipairs(root.children) do
        if n.attrs and n.attrs.id then ctx.anchor_tags[n.attrs.id] = e.tag .. '-' .. util.slug(n.attrs.id) end
      end
      walk(root, ctx, lines, 0)
    end
  end
  lines[#lines + 1] = 'vim:tw=78:ts=8:ft=help:norl:'
  return table.concat(lines, '\n') .. '\n', entries
end

return M
