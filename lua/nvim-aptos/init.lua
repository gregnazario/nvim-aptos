local M = {}

local default_config = {
  syntax = {
    enable = true,
    folds = true,
  },
  lsp = {
    enable = true,
    cmd = { "move-analyzer" },
    keymaps = {
      definition = "gd",
      references = "gr",
      hover = "K",
      rename = "<leader>rn",
      code_action = "<leader>ca",
    },
  },
  cli = {
    enable = true,
    aptos_path = "aptos",
    keymaps = {
      build = "<leader>ab",
      test = "<leader>at",
      publish = "<leader>ap",
    },
  },
  prover = {
    enable = true,
    keymap = "<leader>av",
  },
  explorer = {
    enable = true,
    keymap = "<leader>ae",
  },
  gas = {
    enable = true,
    keymap = "<leader>ag",
  },
}

M.config = {}

function M.setup(config)
  if vim.fn.has("nvim-0.10") == 0 then
    vim.notify("nvim-aptos requires Neovim >= 0.10", vim.log.levels.ERROR)
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, config or {})

  local components = {
    { M.config.syntax.enable, "nvim-aptos.syntax" },
    { M.config.lsp.enable, "nvim-aptos.lsp" },
    { M.config.cli.enable, "nvim-aptos.cli" },
    { M.config.prover.enable, "nvim-aptos.prover" },
    { M.config.explorer.enable, "nvim-aptos.explorer" },
    { M.config.gas.enable, "nvim-aptos.gas" },
  }

  for _, c in ipairs(components) do
    if c[1] then
      local ok, mod = pcall(require, c[2])
      if ok and mod.setup then
        local sok, err = pcall(mod.setup, M.config)
        if not sok then
          vim.notify("nvim-aptos: failed to init " .. c[2] .. ": " .. err, vim.log.levels.WARN)
        end
      end
    end
  end
end

-- Public API: delegate to modules
function M.build()
  require("nvim-aptos.cli").build()
end

function M.test(filter)
  require("nvim-aptos.cli").test(filter)
end

function M.publish()
  require("nvim-aptos.cli").publish()
end

function M.prove(func_name)
  require("nvim-aptos.prover").prove(func_name)
end

function M.explore(address)
  require("nvim-aptos.explorer").explore(address)
end

function M.estimate_gas()
  require("nvim-aptos.gas").estimate()
end

return M
