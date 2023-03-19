local M = {}

local api = vim.api

local utils = require("link-visitor.utils")
local config = require("link-visitor.config")

---Open links in the buffer
---@param bufnr number: buffer id, 0 by default
function M.links_in_buffer(bufnr)
	local links = utils.find_links(api.nvim_buf_get_lines(bufnr or 0, 0, -1, false))
	local filtered_links = {}
	local urls = {}
	for _, link in ipairs(links) do
		if not urls[link.link] then
			urls[link.link] = true
			table.insert(filtered_links, link)
		end
	end
	utils.visit_choose(filtered_links)
end

---Open link under the cursor(search in current line)
function M.link_under_cursor()
	local line = api.nvim_get_current_line()
	local links = utils.find_links({ line })
	if #links > 0 then
		local col = vim.fn.col(".")
		for _, link in ipairs(links) do
			if col >= link.first and col <= link.last then
				utils.visit(link)
				return
			end
		end
	end
	utils.echo("Link not found", "WarningMsg")
end

---Open link near the cursor(search in current line)
function M.link_near_cursor()
	local line = api.nvim_get_current_line()
	local links = utils.find_links({ line })
	local distance = math.huge
	local link
	if #links > 0 then
		local col = vim.fn.col(".")
		for _, l in ipairs(links) do
			if col >= l.first and col <= l.last then
				link = l
				break
			else
				local d = math.min(math.abs(l.first - col), math.abs(l.last - col))
				if d < distance then
					link = l
					distance = d
				end
			end
		end
	end
	if link then
		utils.visit(link)
	else
		utils.echo("Link not found", "WarningMsg")
	end
end

---@param url string
function M.visit(url)
	utils.visit({ link = url })
end

local function setup_hl()
	local hls = {
		Float = "NormalFloat",
		Border = "FloatBorder",
		Text = "MoreMsg",
	}
	for grp, link in pairs(hls) do
		api.nvim_set_hl(0, "LinkVisitor" .. grp, { link = link, default = true })
	end
end

function M.setup(opts)
	config.set(opts)
	api.nvim_create_user_command("VisitLinkInBuffer", function(args)
		local arg = args.args
		local bufnr = vim.fn.bufnr(arg)
		if bufnr ~= -1 then
			bufnr = 0
		end
		M.links_in_buffer(bufnr)
	end, {
		nargs = "?",
		complete = function(word, full)
			if #(vim.split(full, " ")) > 2 then
				return {}
			end
			if word == "" then
				local ret = {}
				local bufs = vim.tbl_filter(function(buf)
					return api.nvim_buf_is_loaded(buf) and api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ""
				end, api.nvim_list_bufs())
				for _, buf in ipairs(bufs) do
					table.insert(ret, api.nvim_buf_get_name(buf))
				end
				return ret
			end
			return {}
		end,
	})
	api.nvim_create_user_command("VisitLinkUnderCursor", M.link_under_cursor, {})
	api.nvim_create_user_command("VisitLinkNearCursor", M.link_near_cursor, {})

	setup_hl()
end

return M
