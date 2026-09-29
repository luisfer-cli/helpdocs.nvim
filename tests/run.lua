vim.opt.runtimepath:prepend(vim.fn.getcwd())
local render = require('helpdocs.parser.vimdoc').render
local util = require('helpdocs.util')

local function has(s, needle)
  assert(s:find(needle, 1, true), ('missing %q'):format(needle))
end

local html = util.read('tests/fixtures/basic.html')
local out, entries = render({
  namespace = 'react',
  name = 'React',
  release = '19.2',
  entries = {
    { name = 'useEffect', path = 'reference/react/useeffect', type = 'Hooks' },
    { name = 'useEffect', path = 'reference/react/useeffect-copy', type = 'Hooks' },
    { name = 'useState', path = 'reference/react/usestate', type = 'Hooks' },
  },
  pages = {
    ['reference/react/useeffect'] = html,
    ['reference/react/useeffect-copy'] = '<p>collision</p>',
    ['reference/react/usestate'] = '<h1>State</h1>',
  },
})

has(out, '*react*')
has(out, '*react-useEffect*')
has(out, '*react-useEffect-2*')
has(out, 'Intro & Unicode ñ')
has(out, '`useEffect`')
has(out, '|react-useState|')
has(out, 'Example: >')
has(out, '    const x = 1 < 2;')
has(out, '<')
has(out, '- one')
has(out, '1. first')
has(out, '    quoted')
has(out, 'Name | Value')
has(out, 'kept text')
assert(entries[1].tag ~= entries[2].tag, 'tag collision not resolved')
print('ok')
