local M = {}
local util = require("nvim-aptos.util")

local aptos_path

--- Parse prover output into quickfix entries.
--- Prover errors follow a similar format to compiler errors.
---@param output string
---@return table[] quickfix entries
local function parse_prover_output(output)
  local entries = {}
  for line in output:gmatch("[^\r\n]+") do
    local file, lnum, col = line:match("[┌├]─%s+(.+):(%d+):(%d+)")
    if file and lnum then
      -- Look for the error text on the same or next matching line
      local text = line:match(":%d+:%s*(.+)$") or "verification error"
      table.insert(entries, {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
        type = "E",
      })
    end
  end
  return entries
end

function M.setup(config)
  aptos_path = config.cli.aptos_path or "aptos"
  local keymap = config.prover.keymap

  local group = vim.api.nvim_create_augroup("NvimAptosProver", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "move",
    callback = function(args)
      local buf = args.buf

      vim.api.nvim_buf_create_user_command(buf, "AptosProve", function(o)
        M.prove(o.args ~= "" and o.args or nil)
      end, { desc = "Run Move Prover", nargs = "?" })

      if keymap then
        vim.keymap.set("n", keymap, function()
          M.prove()
        end, { buffer = buf, desc = "Aptos: Prove" })
      end
    end,
  })
end

function M.prove(func_name)
  local root = util.find_project_root()
  if not root then
    util.notify("No Move.toml found", vim.log.levels.ERROR)
    return
  end

  local cmd = { aptos_path, "move", "prove", "--package-dir", root }
  if func_name then
    vim.list_extend(cmd, { "--filter", func_name })
  end

  util.notify("Running Move Prover...")

  util.run_async(cmd, { cwd = root }, function(code, stdout, stderr)
    local output = stdout .. stderr
    local lines = vim.split(output, "\n", { trimempty = true })

    if code == 0 then
      util.notify("Verification succeeded", vim.log.levels.INFO)
    else
      local entries = parse_prover_output(output)
      if #entries > 0 then
        vim.fn.setqflist(entries, "r")
        vim.cmd("copen")
      end
      if #lines > 0 then
        util.open_float(lines, { title = "Prover Output" })
      end
    end
  end)
end

-- Exposed for testing
M._parse_prover_output = parse_prover_output

return M
