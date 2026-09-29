local installer = require('helpdocs.installer')
local devdocs = require('helpdocs.devdocs')
local M = {}

function M.setup()
  vim.api.nvim_create_user_command('DocsInstall', function(o) installer.install(o.args) end, {
    nargs = 1,
    complete = function(arg)
      local docs = devdocs.cached_manifest() or {}
      local out = {}
      for _, d in ipairs(docs) do if d.slug and d.slug:sub(1, #arg) == arg then out[#out + 1] = d.slug end end
      table.sort(out)
      return out
    end,
  })
  vim.api.nvim_create_user_command('DocsRemove', function(o) installer.remove(o.args) end, { nargs = 1, complete = installer.installed_complete })
  vim.api.nvim_create_user_command('DocsUpdate', function(o) installer.update(o.args) end, { nargs = '?', complete = installer.installed_complete })
  vim.api.nvim_create_user_command('DocsList', function() installer.list() end, {})
end

return M
