local M = {}

--- Find the Move project root by searching upward for Move.toml
---@param start? string starting directory (defaults to current buffer's directory)
---@return string|nil root directory path, or nil if not found
function M.find_project_root(start)
  start = start or vim.fn.expand("%:p:h")
  local found = vim.fs.find("Move.toml", { path = start, upward = true, type = "file" })
  if found[1] then
    return vim.fn.fnamemodify(found[1], ":h")
  end
  return nil
end

--- Run an async command via vim.system
---@param cmd string[] command and arguments
---@param opts? { cwd?: string, on_stdout?: fun(data: string), on_stderr?: fun(data: string) }
---@param callback fun(code: integer, stdout: string, stderr: string)
function M.run_async(cmd, opts, callback)
  opts = opts or {}
  vim.system(cmd, {
    cwd = opts.cwd,
    text = true,
  }, function(result)
    vim.schedule(function()
      callback(result.code, result.stdout or "", result.stderr or "")
    end)
  end)
end

--- Open a floating window with the given lines
---@param lines string[] content lines
---@param opts? { title?: string, width?: integer, height?: integer, filetype?: string }
---@return integer bufnr, integer winnr
function M.open_float(lines, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end

  local width = opts.width or math.min(math.max(60, #(lines[1] or "") + 4), math.floor(vim.o.columns * 0.8))
  local height = opts.height or math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.7)))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = opts.title and (" " .. opts.title .. " ") or nil,
    title_pos = opts.title and "center" or nil,
  })

  -- q to close
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true })

  return buf, win
end

--- Safely decode JSON
---@param str string
---@return any|nil parsed value, or nil on error
---@return string|nil error message
function M.parse_json(str)
  local ok, result = pcall(vim.json.decode, str)
  if ok then
    return result, nil
  end
  return nil, result
end

--- Notify with nvim-aptos prefix
---@param msg string
---@param level? integer vim.log.levels.*
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "nvim-aptos" })
end

return M
