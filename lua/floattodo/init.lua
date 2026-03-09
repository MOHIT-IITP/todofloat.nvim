local M = {}

local function expand_path(path)
  if path:sub(1,1) == "~" then
    return os.getenv("HOME") .. path:sub(2)
  end
  return path
end

local function center_in(outer, inner)
  return math.floor((outer - inner) / 2)
end

local function win_config()
  local width = math.min(math.floor(vim.o.columns * 0.7), 80)
  local height = math.min(math.floor(vim.o.lines * 0.7), 25)

  return {
    relative = "editor",
    width = width,
    height = height,
    col = center_in(vim.o.columns, width),
    row = center_in(vim.o.lines, height),
    border = "rounded",
    style = "minimal"
  }
end

local function create_footer()
  local buf = vim.api.nvim_create_buf(false, true)

  local text = " q: quit │ w: save │ a: add task "
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  return buf
end

local function highlight_todos(buf)
  vim.api.nvim_buf_add_highlight(buf, -1, "Todo", 0, 0, -1)
end

local function ensure_file_exists(path)
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({ "# TODO", "" }, path)
  end
end

local function add_task(buf)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, { "- [ ] " })
  vim.api.nvim_win_set_cursor(0, { row + 1, 6 })
  vim.cmd("startinsert")
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

  highlight_todos(buf)

  -- footer
  local footer = create_footer()

  vim.api.nvim_open_win(footer, false, {
    relative = "win",
    win = win,
    height = 1,
    width = win_config().width,
    row = win_config().height,
    col = 0,
    style = "minimal",
  })

  -- keymaps
  local map = function(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, silent = true })
  end

  map("q", function()
    if vim.bo.modified then
      vim.notify("Save changes first!", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_win_close(win, true)
  end)

  map("w", function()
    vim.cmd("write")
    vim.notify("Todo saved")
  end)

  map("a", function()
    add_task(buf)
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
