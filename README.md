# helpdocs.nvim

Minimal Neovim plugin that installs DevDocs documentation as native Vim help.
No custom viewer: after installing, use `:help`.

```vim
:DocsInstall react
:h react
:h react-useEffect
:DocsSearch useEffect
```

## Requirements

- Neovim 0.10+
- `curl`
- `tar`
- `rg` optional; falls back to `grep` for `:DocsSearch`
- Network access to `https://devdocs.io/docs.json` and `https://downloads.devdocs.io/`

## Install

Use your plugin manager, for example lazy.nvim:

```lua
{ 'luisfer-cli/helpdocs.nvim' }
```

## Commands

- `:DocsInstall <doc>`: download, convert and install a DevDocs docset.
- `:DocsRemove <doc>`: remove an installed docset.
- `:DocsUpdate [doc]`: reinstall one docset or all installed docsets.
- `:DocsList`: list installed docsets.
- `:DocsSearch <text>`: search installed docsets with `rg` or `grep`, then pick a match.

Install completion uses the cached DevDocs manifest after the first install.
`DocsSearch` searches only installed docsets and opens the selected match.

## Storage

Docsets are stored under:

```text
stdpath('data')/helpdocs/docs/<doc>/doc/<doc>.txt
stdpath('data')/helpdocs/registry.json
```

They are added to `runtimepath` on startup, so help keeps working after restart.

## How it works

1. Fetch `https://devdocs.io/docs.json`.
2. Resolve the requested slug/name/alias.
3. Download `https://downloads.devdocs.io/<slug>.tar.gz`.
4. Read DevDocs `index.json` and `db.json`.
5. Render normalized HTML fragments to Vimdoc.
6. Generate `:helptags`.

Tags are namespaced with the docset slug, e.g. `react-useEffect`, to avoid global
Vim help collisions.

## Limitations

The converter is intentionally small. It supports headings, paragraphs, code
blocks, inline code, links, lists, blockquotes and simple tables. Decorative HTML
is ignored. Some DevDocs pages may render imperfectly; contributions should add a
small fixture test before expanding the converter.

## Contributing

Keep the plugin boring: no alternate viewer, no picker dependency, no bundled
docsets. Improve the source adapter or `lua/helpdocs/parser/vimdoc.lua` with
fixture coverage in `tests/`.
