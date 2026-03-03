local M = {}
local util = require("nvim-aptos.util")

local aptos_path

--- Try to read the default account address from .aptos/config.yaml
---@return string|nil
local function default_address()
  local root = util.find_project_root() or vim.fn.getcwd()
  local config_path = root .. "/.aptos/config.yaml"
  local f = io.open(config_path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  -- Simple YAML parse for account_address
  local addr = content:match("account:%s*(0x%x+)") or content:match("account_address:%s*(0x%x+)")
  return addr
end

--- Format resource JSON into readable lines with foldable sections
---@param resources table[]
---@return string[]
local function format_resources(resources)
  local lines = {}
  for _, res in ipairs(resources) do
    local type_name = res.type or "unknown"
    table.insert(lines, "── " .. type_name .. " ──")
    local json_str = vim.json.encode(res.data or res)
    -- Pretty-print JSON
    local ok, formatted = pcall(function()
      return vim.fn.json_encode(vim.json.decode(json_str))
    end)
    if ok then
      for _, l in ipairs(vim.split(formatted, "\n")) do
        table.insert(lines, "  " .. l)
      end
    else
      table.insert(lines, "  " .. json_str)
    end
    table.insert(lines, "")
  end
  return lines
end

function M.setup(config)
  aptos_path = config.cli.aptos_path or "aptos"
  local keymap = config.explorer.keymap

  local group = vim.api.nvim_create_augroup("NvimAptosExplorer", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "move",
    callback = function(args)
      local buf = args.buf

      vim.api.nvim_buf_create_user_command(buf, "AptosExplore", function(o)
        M.explore(o.args ~= "" and o.args or nil)
      end, { desc = "Explore on-chain resources", nargs = "?" })

      if keymap then
        vim.keymap.set("n", keymap, function()
          M.explore()
        end, { buffer = buf, desc = "Aptos: Explore" })
      end
    end,
  })
end

function M.explore(address)
  address = address or default_address()
  if not address then
    vim.ui.input({ prompt = "Account address: " }, function(input)
      if input and input ~= "" then
        M.explore(input)
      end
    end)
    return
  end

  local cmd = {
    aptos_path, "account", "list",
    "--account", address,
    "--query", "resources",
    "--output", "json",
  }

  util.notify("Fetching resources for " .. address .. "...")

  util.run_async(cmd, {}, function(code, stdout, stderr)
    if code ~= 0 then
      util.notify("Failed to fetch resources: " .. stderr, vim.log.levels.ERROR)
      return
    end

    local data = util.parse_json(stdout)
    if not data then
      util.notify("Failed to parse response", vim.log.levels.ERROR)
      return
    end

    -- data may be a table of resources
    local resources = data
    if type(data) == "table" and data.Result then
      resources = data.Result
    end

    if type(resources) ~= "table" or #resources == 0 then
      util.notify("No resources found for " .. address, vim.log.levels.INFO)
      return
    end

    local lines = format_resources(resources)
    local buf, win = util.open_float(lines, { title = "Resources: " .. address, filetype = "json" })

    -- CR to toggle fold
    vim.keymap.set("n", "<CR>", "za", { buffer = buf })
  end)
end

return M
