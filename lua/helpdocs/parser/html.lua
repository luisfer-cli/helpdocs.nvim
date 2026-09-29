local M = {}

local void = { br=true, hr=true, img=true, input=true, meta=true, link=true, area=true, base=true, col=true, embed=true, param=true, source=true, track=true, wbr=true }
local skip = { script=true, style=true, svg=true }

function M.decode(s)
  return (s or '')
    :gsub('&nbsp;', ' '):gsub('&amp;', '&'):gsub('&lt;', '<'):gsub('&gt;', '>')
    :gsub('&quot;', '"'):gsub('&#39;', "'"):gsub('&apos;', "'")
    :gsub('&#x(%x+);', function(n) return vim.fn.nr2char(tonumber(n, 16)) end)
    :gsub('&#(%d+);', function(n) return vim.fn.nr2char(tonumber(n)) end)
end

local function attrs(s)
  local a = {}
  for k, q, v in s:gmatch('([%w_:%-]+)%s*=%s*(["\'])(.-)%2') do a[k:lower()] = M.decode(v) end
  for k, v in s:gmatch('([%w_:%-]+)%s*=%s*([^%s"\'>/]+)') do a[k:lower()] = M.decode(v) end
  return a
end

function M.parse(html)
  html = (html or ''):gsub('<!%-%-.-%-%->', '')
  local root = { tag='root', attrs={}, children={} }
  local stack = { root }
  local i = 1
  while true do
    local a, b = html:find('<[^>]*>', i)
    local text = a and html:sub(i, a - 1) or html:sub(i)
    if text ~= '' and not skip[stack[#stack].tag] then table.insert(stack[#stack].children, { text = M.decode(text) }) end
    if not a then break end
    local raw = html:sub(a + 1, b - 1)
    local closing = raw:match('^%s*/%s*([%w:-]+)')
    if closing then
      closing = closing:lower()
      for n = #stack, 2, -1 do
        local node = table.remove(stack)
        if node.tag == closing then break end
      end
    else
      local name, rest = raw:match('^%s*([%w:-]+)(.-)%s*/?%s*$')
      if name then
        name = name:lower()
        local node = { tag=name, attrs=attrs(rest or ''), children={} }
        if not skip[name] then table.insert(stack[#stack].children, node) end
        if not void[name] and not raw:match('/%s*$') then table.insert(stack, node) end
      end
    end
    i = b + 1
  end
  return root
end

return M
