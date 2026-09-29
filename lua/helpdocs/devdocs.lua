local util = require('helpdocs.util')
local M = {}
M.manifest_url = 'https://devdocs.io/docs.json'

function M.manifest_path()
  return util.join(vim.fn.stdpath('cache'), 'helpdocs', 'docs.json')
end

function M.fetch_manifest(cb)
  local path = M.manifest_path()
  util.mkdir(vim.fn.fnamemodify(path, ':h'))
  util.system({ 'curl', '-L', '-A', 'helpdocs.nvim', '-f', '-sS', '-o', path, M.manifest_url }, {}, function(err)
    if err then return cb(err) end
    cb(nil, vim.json.decode(util.read(path)))
  end)
end

function M.cached_manifest()
  local path = M.manifest_path()
  if vim.fn.filereadable(path) == 1 then return vim.json.decode(util.read(path)) end
end

local function str(v)
  return type(v) == 'string' and v or ''
end

function M.resolve(name, docs)
  name = name:lower()
  for _, d in ipairs(docs or {}) do
    if str(d.slug):lower() == name or str(d.name):lower() == name or str(d.alias):lower() == name then return d end
  end
  for _, d in ipairs(docs or {}) do
    if str(d.slug):lower():match('^' .. vim.pesc(name) .. '~') then return d end
  end
end

function M.complete(prefix, cb)
  local docs = M.cached_manifest()
  local function done(list)
    local out = {}
    for _, d in ipairs(list or {}) do
      local s = d.slug
      if s and s:sub(1, #prefix) == prefix then out[#out + 1] = s end
    end
    table.sort(out); cb(out)
  end
  if docs then done(docs) else M.fetch_manifest(function(_, list) done(list or {}) end) end
end

return M
