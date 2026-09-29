local util = require('helpdocs.util')
local M = {}
M.path = util.join(vim.fn.stdpath('data'), 'helpdocs', 'registry.json')

function M.load()
  if vim.fn.filereadable(M.path) == 0 then return { docs = {} } end
  return vim.json.decode(util.read(M.path)) or { docs = {} }
end

function M.save(reg)
  util.write(M.path, vim.json.encode(reg))
end

return M
