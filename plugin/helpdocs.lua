if vim.g.loaded_helpdocs_nvim then return end
vim.g.loaded_helpdocs_nvim = true
require('helpdocs').setup()
