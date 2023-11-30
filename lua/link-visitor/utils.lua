local M = {}

local api, fn = vim.api, vim.fn

local config = require('link-visitor.config')

local PATTERN =
  '\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*\\})\\})+'

---@class Link
---@field link string: text of link
---@field lnum number: line number
---@field first number: start column
---@field last number: last column

---@param lines string[]
---@return Link[]
function M.find_links(lines)
  ---@type Link[]
  local ret = {}
  for lnum, line in ipairs(lines) do
    local link = ''
    local last = 0
    local first = 0
    while true do
      link, first, last = unpack(fn.matchstrpos(line, PATTERN, last))
      link = vim.trim(link)
      if link == '' then break end
      table.insert(ret, { link = link, lnum = lnum, first = first, last = last })
    end
  end
  return ret
end

local function confirm(msg)
  -- skip confirmation step
  if config.skip_confirmation then return true end

  vim.cmd([[echon '']])
  local lines, hls = { msg .. ' (y/n)' }, { 'LinkVisitorText' }

  -- information
  local bufnr = api.nvim_create_buf(false, true)
  local height = #lines
  local width = math.max(unpack(vim.tbl_map(function(line) return fn.strwidth(line) end, lines)))

  api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

  local border = config.border
  local winnr = api.nvim_open_win(bufnr, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 4,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    zindex = 500,
    border = vim.tbl_contains({ nil, false, 'none' }, border) and 'none' or border,
  })
  local winhl = 'NormalFloat:LinkVisitorFloat'
  if fn.hlexists('FloatBorder') == 1 then winhl = winhl .. ',FloatBorder:LinkVisitorBorder' end
  vim.wo[winnr].winblend = 0
  vim.wo[winnr].winhl = winhl

  local ns = api.nvim_create_namespace('getchar')
  for idx, hl in ipairs(hls) do
    if hl ~= 'NONE' then api.nvim_buf_add_highlight(bufnr, ns, hl, idx - 1, 0, -1) end
  end

  -- bg1 background
  local bg_bufnr = api.nvim_create_buf(false, true)
  local bg_height = math.min(vim.o.lines, height + 4)
  local bg_width = math.min(vim.o.columns, width + 10)
  vim.bo[bg_bufnr].readonly = true
  local bg_winnr = api.nvim_open_win(bg_bufnr, false, {
    style = 'minimal',
    relative = 'editor',
    width = bg_width,
    height = bg_height,
    row = math.floor((vim.o.lines - bg_height) / 2) - 4,
    col = math.floor((vim.o.columns - bg_width) / 2),
    zindex = 450,
  })
  vim.wo[bg_winnr].winblend = 0

  -- bg2 overlay
  local bg_bufnr_2 = api.nvim_create_buf(false, true)
  vim.bo[bg_bufnr_2].readonly = true
  local bg_winnr_2 = api.nvim_open_win(bg_bufnr_2, false, {
    style = 'minimal',
    relative = 'editor',
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    zindex = 400,
  })
  vim.wo[bg_winnr_2].winblend = 50

  vim.cmd([[redraw]])

  local c = fn.getchar()
  while type(c) ~= 'number' do
    c = fn.getchar()
  end
  for _, win in ipairs({ winnr, bg_winnr, bg_winnr_2 }) do
    pcall(api.nvim_win_close, win, { force = true })
  end
  for _, buf in ipairs({ bufnr, bg_bufnr, bg_bufnr_2 }) do
    pcall(api.nvim_buf_delete, buf, { force = true })
  end
  return fn.nr2char(c) == 'y'
end

---@param link Link
function M.visit(link)
  if confirm('Visit ' .. link.link .. ' ?') then
    fn.jobstart(string.format('%s %s', config.open_cmd, link.link), {
      on_stderr = function(_, data)
        local msg = table.concat(data or {}, '\n')
        if msg ~= '' then print(msg) end
      end,
    })
  end
end

---@param links Link[]
function M.visit_choose(links)
  if #links == 0 then
    M.echo('No links found', 'WarningMsg')
  elseif #links == 1 then
    M.visit(links[1])
  else
    vim.ui.select(links, {
      prompt = 'Select one link to visit',
      format_item = function(link) return link.link end,
    }, function(link)
      if link then M.visit(link) end
    end)
  end
end

function M.echo(msg, group)
  if not config.silent then
    api.nvim_echo({ { string.format('[link-vistor]: %s', msg), group } }, false, {})
  end
end

return M
