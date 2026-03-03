local M = {}
local util = require("nvim-aptos.util")

local aptos_path

function M.setup(config)
  aptos_path = config.cli.aptos_path or "aptos"
  local keymap = config.gas.keymap

  local group = vim.api.nvim_create_augroup("NvimAptosGas", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "move",
    callback = function(args)
      local buf = args.buf

      vim.api.nvim_buf_create_user_command(buf, "AptosGas", function()
        M.estimate()
      end, { desc = "Estimate gas for publish" })

      if keymap then
        vim.keymap.set("n", keymap, M.estimate, { buffer = buf, desc = "Aptos: Gas estimate" })
      end
    end,
  })
end

function M.estimate()
  local root = util.find_project_root()
  if not root then
    util.notify("No Move.toml found", vim.log.levels.ERROR)
    return
  end

  local cmd = {
    aptos_path, "move", "publish",
    "--package-dir", root,
    "--simulate",
    "--output", "json",
  }

  util.notify("Simulating transaction...")

  util.run_async(cmd, { cwd = root }, function(code, stdout, stderr)
    local output = stdout .. stderr
    local data = util.parse_json(stdout)

    if code ~= 0 or not data then
      local lines = vim.split(output, "\n", { trimempty = true })
      if #lines > 0 then
        util.open_float(lines, { title = "Gas Simulation Error" })
      else
        util.notify("Simulation failed", vim.log.levels.ERROR)
      end
      return
    end

    -- Navigate into the result structure
    local result = data
    if type(data) == "table" and data.Result then
      result = data.Result
    end

    local gas_used = result.gas_used or result.gas_unit_price and "N/A" or "unknown"
    local gas_price = result.gas_unit_price or "unknown"
    local success = result.success
    local vm_status = result.vm_status or "unknown"

    local lines = {
      "Gas Estimation",
      string.rep("─", 40),
      "",
      "  Gas units used:   " .. tostring(gas_used),
      "  Gas unit price:   " .. tostring(gas_price),
      "",
    }

    -- Calculate estimated cost if both values are numbers
    local gas_num = tonumber(gas_used)
    local price_num = tonumber(gas_price)
    if gas_num and price_num then
      local cost = gas_num * price_num
      table.insert(lines, "  Estimated cost:   " .. tostring(cost) .. " octas")
      table.insert(lines, "                    " .. string.format("%.8f APT", cost / 1e8))
      table.insert(lines, "")
    end

    table.insert(lines, "  Simulation:       " .. (success == true and "SUCCESS" or "FAILED"))
    table.insert(lines, "  VM status:        " .. tostring(vm_status))

    util.open_float(lines, { title = "Gas Estimation" })
  end)
end

return M
