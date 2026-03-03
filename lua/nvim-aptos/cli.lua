local M = {}
local util = require("nvim-aptos.util")

local aptos_path
local keymaps

--- Parse Aptos compiler errors into quickfix entries.
--- Aptos errors use the format: ┌─ path/file.move:LINE:COL
---@param output string combined stdout+stderr
---@return table[] quickfix entries
local function parse_errors(output)
  local entries = {}
  local current_text = nil

  for line in output:gmatch("[^\r\n]+") do
    -- Match error location: ┌─ or ├─ followed by path:line:col
    local file, lnum, col = line:match("[┌├]─%s+(.+):(%d+):(%d+)")
    if file and lnum then
      if current_text then
        table.insert(entries, {
          filename = file,
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = current_text,
        })
      end
      current_text = nil
    end

    -- Match error/warning message lines
    local msg = line:match("^error%[.*%]:%s*(.+)") or line:match("^error:%s*(.+)")
    if msg then
      current_text = msg
    end
  end

  return entries
end

--- Run an aptos CLI command with standard output handling
---@param cmd string[] command arguments (after "aptos")
---@param opts { cwd?: string, on_success?: fun(stdout: string), title?: string }
local function run_cmd(cmd, opts)
  opts = opts or {}
  local full_cmd = { aptos_path }
  vim.list_extend(full_cmd, cmd)

  local cwd = opts.cwd or util.find_project_root()

  util.run_async(full_cmd, { cwd = cwd }, function(code, stdout, stderr)
    local output = stdout .. stderr
    if code == 0 then
      if opts.on_success then
        opts.on_success(output)
      else
        util.notify(opts.title or "Command completed", vim.log.levels.INFO)
      end
    else
      local entries = parse_errors(output)
      if #entries > 0 then
        vim.fn.setqflist(entries, "r")
        vim.cmd("copen")
      end
      -- Show output in floating window for context
      local lines = vim.split(output, "\n", { trimempty = true })
      if #lines > 0 then
        util.open_float(lines, { title = opts.title or "Aptos Error" })
      end
    end
  end)
end

function M.setup(config)
  aptos_path = config.cli.aptos_path or "aptos"
  keymaps = config.cli.keymaps

  local group = vim.api.nvim_create_augroup("NvimAptosCli", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "move",
    callback = function(args)
      local buf = args.buf
      local bopts = { buffer = buf }

      -- Commands
      vim.api.nvim_buf_create_user_command(buf, "AptosBuild", function()
        M.build()
      end, { desc = "Compile Move package" })

      vim.api.nvim_buf_create_user_command(buf, "AptosTest", function(o)
        M.test(o.args ~= "" and o.args or nil)
      end, { desc = "Run Move tests", nargs = "?" })

      vim.api.nvim_buf_create_user_command(buf, "AptosPublish", function()
        M.publish()
      end, { desc = "Publish Move modules" })

      vim.api.nvim_buf_create_user_command(buf, "AptosInit", function(o)
        M.init_project(o.args ~= "" and o.args or nil)
      end, { desc = "Initialize Move project", nargs = "?" })

      vim.api.nvim_buf_create_user_command(buf, "AptosAccount", function()
        M.account()
      end, { desc = "Show account info" })

      vim.api.nvim_buf_create_user_command(buf, "AptosNetwork", function(o)
        M.network(o.args ~= "" and o.args or nil)
      end, { desc = "Switch Aptos network", nargs = "?" })

      -- Keymaps
      if keymaps.build then
        vim.keymap.set("n", keymaps.build, M.build, vim.tbl_extend("force", bopts, { desc = "Aptos: Build" }))
      end
      if keymaps.test then
        vim.keymap.set("n", keymaps.test, M.test, vim.tbl_extend("force", bopts, { desc = "Aptos: Test" }))
      end
      if keymaps.publish then
        vim.keymap.set("n", keymaps.publish, M.publish, vim.tbl_extend("force", bopts, { desc = "Aptos: Publish" }))
      end
    end,
  })
end

function M.build()
  local root = util.find_project_root()
  if not root then
    util.notify("No Move.toml found", vim.log.levels.ERROR)
    return
  end
  util.notify("Compiling...")
  run_cmd({ "move", "compile", "--package-dir", root }, {
    title = "Build",
    on_success = function()
      util.notify("Build succeeded", vim.log.levels.INFO)
    end,
  })
end

function M.test(filter)
  local root = util.find_project_root()
  if not root then
    util.notify("No Move.toml found", vim.log.levels.ERROR)
    return
  end
  local cmd = { "move", "test", "--package-dir", root }
  if filter then
    vim.list_extend(cmd, { "--filter", filter })
  end
  util.notify("Running tests...")
  run_cmd(cmd, {
    title = "Test",
    on_success = function(output)
      local lines = vim.split(output, "\n", { trimempty = true })
      util.open_float(lines, { title = "Test Results" })
    end,
  })
end

function M.publish()
  local root = util.find_project_root()
  if not root then
    util.notify("No Move.toml found", vim.log.levels.ERROR)
    return
  end
  vim.ui.select({ "Yes", "No" }, { prompt = "Publish modules?" }, function(choice)
    if choice ~= "Yes" then
      return
    end
    util.notify("Publishing...")
    run_cmd({ "move", "publish", "--package-dir", root }, {
      title = "Publish",
      on_success = function(output)
        util.notify("Publish succeeded", vim.log.levels.INFO)
      end,
    })
  end)
end

function M.init_project(name)
  if not name then
    vim.ui.input({ prompt = "Project name: " }, function(input)
      if input and input ~= "" then
        M.init_project(input)
      end
    end)
    return
  end
  run_cmd({ "move", "init", "--name", name }, {
    title = "Init",
    on_success = function()
      util.notify("Project '" .. name .. "' initialized", vim.log.levels.INFO)
    end,
  })
end

function M.account()
  run_cmd({ "account", "list" }, {
    title = "Account",
    on_success = function(output)
      local lines = vim.split(output, "\n", { trimempty = true })
      util.open_float(lines, { title = "Account Info" })
    end,
  })
end

function M.network(net)
  if not net then
    vim.ui.select({ "devnet", "testnet", "mainnet", "local" }, {
      prompt = "Select network:",
    }, function(choice)
      if choice then
        M.network(choice)
      end
    end)
    return
  end
  run_cmd({ "init", "--network", net }, {
    title = "Network",
    on_success = function()
      util.notify("Switched to " .. net, vim.log.levels.INFO)
    end,
  })
end

-- Exposed for testing
M._parse_errors = parse_errors

return M
