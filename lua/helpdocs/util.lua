local M = {}

function M.join(...)
  return table.concat(vim.tbl_map(tostring, { ... }), '/')
end

function M.mkdir(path)
  vim.fn.mkdir(path, 'p')
end

function M.read(path)
  local f = assert(io.open(path, 'rb'))
  local s = f:read('*a')
  f:close()
  return s
end

function M.write(path, s)
  M.mkdir(vim.fn.fnamemodify(path, ':h'))
  local f = assert(io.open(path, 'wb'))
  f:write(s)
  f:close()
end

function M.rm_rf(path)
  if path and path ~= '' then vim.fn.delete(path, 'rf') end
end

function M.system(cmd, opts, cb)
  opts = opts or {}
  vim.system(cmd, opts, function(res)
    vim.schedule(function()
      if res.code == 0 then cb(nil, res) else cb((res.stderr ~= '' and res.stderr or table.concat(cmd, ' ')), res) end
    end)
  end)
end

function M.slug(s)
  s = tostring(s or ''):gsub('&[%w#]+;', ''):gsub('<[^>]+>', '')
  s = s:gsub('%b()', ''):gsub('[<>%[%]{}"\'`]', ''):gsub('%s+', '-')
  s = s:gsub('[/:]+', '-'):gsub('[^%w%._%-]+', ''):gsub('%-+', '-')
  s = s:gsub('^%-+', ''):gsub('%-+$', '')
  return s ~= '' and s or 'index'
end

function M.wrap(line, width)
  width = width or 78
  if #line <= width or line:match('^%s') then return { line } end
  local out = {}
  while #line > width do
    local cut = line:sub(1, width):match('^.*()%s+') or width
    out[#out + 1] = vim.trim(line:sub(1, cut))
    line = vim.trim(line:sub(cut + 1))
  end
  out[#out + 1] = line
  return out
end

return M
