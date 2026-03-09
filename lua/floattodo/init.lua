local M = {}

local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

local function center_in(outer, inner)
	return math.floor((outer - inner) / 2)
end

local function win_config()
	local width = math.min(math.floor(vim.o.columns * 0.8), 64)
	local height = math.floor(vim.o.lines * 0.8)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = center_in(vim.o.columns, width),
		row = center_in(vim.o.lines, height),
		border = "single",
	}
end

local function ensure_file_exists(path)
	if vim.fn.filereadable(path) == 0 then
		vim.fn.writefile({ "# TODO", "" }, path)
	end
end

local function toggle_checkbox(buf)
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]

	if not line then
		return
	end

	if line:match("%- %[ %]") then
		line = line:gsub("%- %[ %]", "- [x]", 1)
	elseif line:match("%- %[x%]") then
		line = line:gsub("%- %[x%]", "- [ ]", 1)
	else
		return
	end

	vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { line })
end

local function open_floating_file(target_file)
	local expanded_path = expand_path(target_file)

	ensure_file_exists(expanded_path)

	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "markdown"

	local win = vim.api.nvim_open_win(buf, true, win_config())

	local map = function(key, fn)
		vim.keymap.set("n", key, fn, { buffer = buf, silent = true })
	end

	map("q", function()
		if vim.bo.modified then
			vim.notify("Save your changes first", vim.log.levels.WARN)
			return
		end
		vim.api.nvim_win_close(win, true)
	end)


	map("x", function()
		toggle_checkbox(buf)
	end)
end

local function setup_user_commands(opts)
	local target_file = opts.target_file or "~/todo.md"

	vim.api.nvim_create_user_command("Td", function()
		open_floating_file(target_file)
	end, {})
end

function M.setup(opts)
	opts = opts or {}
	setup_user_commands(opts)
end

return M
