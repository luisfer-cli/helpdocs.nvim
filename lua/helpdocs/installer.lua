local devdocs = require('helpdocs.devdocs')
local registry = require('helpdocs.registry')
local render = require('helpdocs.parser.vimdoc').render
local util = require('helpdocs.util')
local M = {}

function M.root() return util.join(vim.fn.stdpath('data'), 'helpdocs', 'docs') end
local function safe_slug(slug)
  return (slug:gsub('~', '-'))
end
local function docdir(slug) return util.join(M.root(), safe_slug(slug)) end
local function msg(s) vim.notify(s, vim.log.levels.INFO, { title = 'helpdocs.nvim' }) end
local function err(s) vim.notify(s, vim.log.levels.ERROR, { title = 'helpdocs.nvim' }) end
local function rtp_add(path) if not vim.o.runtimepath:find(vim.pesc(path), 1) then vim.opt.runtimepath:prepend(path) end end

function M.load_installed()
  for slug in pairs(registry.load().docs or {}) do rtp_add(docdir(slug)) end
end

local function install_doc(d)
  local slug = d.slug
  local target = docdir(slug)
  local tmp = util.join(vim.fn.tempname(), safe_slug(slug))
  local tarball = tmp .. '.tar.gz'
  util.mkdir(tmp)
  msg('Downloading ' .. d.name .. ' documentation...')
  util.system({ 'curl', '-L', '-A', 'helpdocs.nvim', '-f', '-sS', '-o', tarball, 'https://downloads.devdocs.io/' .. slug .. '.tar.gz' }, {}, function(e)
    if e then util.rm_rf(tmp); return err('Download failed: ' .. e) end
    util.system({ 'tar', '-xzf', tarball, '-C', tmp }, {}, function(e2)
      if e2 then util.rm_rf(tmp); return err('Bundle extraction failed: ' .. e2) end
      local base = tmp
      if vim.fn.filereadable(util.join(base, 'index.json')) == 0 then base = util.join(tmp, slug) end
      if vim.fn.filereadable(util.join(base, 'index.json')) == 0 then util.rm_rf(tmp); return err('Bundle has no index.json') end
      msg('Converting ' .. d.name .. ' documentation...')
      local ok, vimdoc_or_err = pcall(function()
        local index = vim.json.decode(util.read(util.join(base, 'index.json')))
        local pages = vim.json.decode(util.read(util.join(base, 'db.json')))
        local text = render({ namespace = slug:gsub('~.*$', ''), name = d.name, release = d.release or d.version, entries = index.entries, pages = pages })
        util.rm_rf(target)
        util.write(util.join(target, 'doc', slug:gsub('~', '-') .. '.txt'), text)
      end)
      util.rm_rf(tmp); util.rm_rf(tarball)
      if not ok then return err('Conversion failed: ' .. vimdoc_or_err) end
      vim.cmd('silent! helptags ' .. vim.fn.fnameescape(util.join(target, 'doc')))
      rtp_add(target)
      local reg = registry.load()
      reg.docs[slug] = { name = d.name, slug = slug, version = d.version, release = d.release, mtime = d.mtime, installed_at = os.time() }
      registry.save(reg)
      msg(d.name .. ' documentation installed.')
    end)
  end)
end

function M.install(name)
  devdocs.fetch_manifest(function(e, docs)
    if e then return err('Could not fetch DevDocs manifest: ' .. e) end
    local d = devdocs.resolve(name, docs)
    if not d then return err('Unknown DevDocs docset: ' .. name) end
    install_doc(d)
  end)
end

function M.remove(name)
  local reg = registry.load()
  local slug = name
  if not reg.docs[slug] then for s, d in pairs(reg.docs) do if d.name:lower() == name:lower() then slug = s end end end
  if not reg.docs[slug] then return err('Not installed: ' .. name) end
  util.rm_rf(docdir(slug))
  reg.docs[slug] = nil
  registry.save(reg)
  msg('Removed ' .. slug .. ' documentation.')
end

function M.update(name)
  if name and name ~= '' then return M.install(name) end
  for slug in pairs(registry.load().docs or {}) do M.install(slug) end
end

function M.list()
  local rows = {}
  for slug, d in pairs(registry.load().docs or {}) do rows[#rows + 1] = string.format('%s\t%s\t%s', slug, d.name or '', d.release or d.version or '') end
  table.sort(rows)
  print(#rows > 0 and table.concat(rows, '\n') or 'No DevDocs documentation installed.')
end

function M.installed_complete(prefix)
  local out = {}
  for slug in pairs(registry.load().docs or {}) do if slug:sub(1, #prefix) == prefix then out[#out + 1] = slug end end
  table.sort(out); return out
end

return M
