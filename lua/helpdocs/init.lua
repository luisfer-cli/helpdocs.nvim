local M = {}

function M.setup()
  require('helpdocs.installer').load_installed()
  require('helpdocs.commands').setup()
end

return M
