local installer = require('helpdocs.installer')
local M = {}

local function msg(s) vim.notify(s, vim.log.levels.INFO, { title = 'helpdocs.nvim' }) end
local function err(s) vim.notify(s, vim.log.levels.ERROR, { title = 'helpdocs.nvim' }) end

local function command(query)
  local root = installer.root()
  if vim.fn.isdirectory(root) == 0 then return nil, 'No DevDocs documentation installed.' end
  if vim.fn.executable('rg') == 1 then
    return { 'rg', '--vimgrep', '--fixed-strings', '--', query, root }
  end
  return { 'grep', '-R', '-n', '-I', '-F', '--', query, root }
end

local function parse(line, has_col)
  local path, lnum, col, text
  if has_col then
    path, lnum, col, text = line:match('^([^:]+):(%d+):(%d+):(.*)$')
  else
    path, lnum, text = line:match('^([^:]+):(%d+):(.*)$')
    col = 1
  end
  if not path then return end
  local doc = vim.fn.fnamemodify(path, ':t:r')
  return { path = path, lnum = tonumber(lnum), col = tonumber(col), text = vim.trim(text), doc = doc }
end

function M.search(query)
  query = vim.trim(query or '')
  if query == '' then
    return vim.ui.input({ prompt = 'Docs search: ' }, function(input) if input then M.search(input) end end)
  end

  local cmd, e = command(query)
  if e then return err(e) end
  local has_col = cmd[1] == 'rg'
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 and (res.stdout or '') == '' then return msg('No matches for: ' .. query) end
      local items = {}
      for line in (res.stdout or ''):gmatch('[^\n]+') do
        local item = parse(line, has_col)
        if item then items[#items + 1] = item end
      end
      if #items == 0 then return msg('No matches for: ' .. query) end
      vim.ui.select(items, {
        prompt = 'Docs matches for "' .. query .. '"',
        format_item = function(i) return string.format('%s:%d: %s', i.doc, i.lnum, i.text) end,
      }, function(i)
        if not i then return end
        vim.cmd('edit +' .. i.lnum .. ' ' .. vim.fn.fnameescape(i.path))
        pcall(vim.api.nvim_win_set_cursor, 0, { i.lnum, math.max(0, i.col - 1) })
      end)
    end)
  end)
end

return M
