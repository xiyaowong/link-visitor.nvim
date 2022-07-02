# link-visitor

![link-visitor-demo](https://user-images.githubusercontent.com/47070852/177006635-ed9ff276-8f3d-4c42-9f94-2f6356e34eb2.gif)

## Installation

`xiyaowong/link-visitor.nvim`

Same as other normal plugins, use your favourite plugin manager to install.

## Setup

```lua
require("link-visitor").setup({
	open_cmd = nil, --[[ cmd to open url
  defaults:
  win or wsl: cmd.exe /c start
  mac: open
  linux: xdg-open
  ]]
	silent = true, -- disable all prints, `false` by default
})
```

## API

```lua
local lv = require 'link-visitor'

lv.links_in_buffer(bufnr?) -- Open links in the buffer, current buffer by default
lv.link_under_cursor() -- Open link under the cursor(search in current line)
lv.link_near_cursor() -- Open link near the cursor(search in current line)
lv.visit(url) -- Open the url
```

## Commands

- `VisitLinkInBuffer` - Open links in the buffer
- `VisitLinkUnderCursor` - Open link under the cursor
- `VisitLinkNearCursor` - Open link near the cursor

## Example

This plugin is useful for lsp-hover documentation

After entering the float window, use `K` to open link under the cursor,
`L` to open link near the cursor

`coc.nvim`

```lua
vim.api.nvim_create_autocmd("User", {
	callback = function()
		local ok, buf = pcall(vim.api.nvim_win_get_buf, vim.g.coc_last_float_win)
		if ok then
			vim.keymap.set("n", "K", function()
				require("link-visitor").link_under_cursor()
			end, { buffer = buf })
			vim.keymap.set("n", "L", function()
				require("link-visitor").link_near_cursor()
			end, { buffer = buf })
		end
	end,
	pattern = "CocOpenFloat",
})
```

`native-lsp`

TODO
