local M = {}
local util = require("nvim-aptos.util")

local function set_keymaps(buf, keymaps)
  local mappings = {
    { keymaps.definition, vim.lsp.buf.definition, "Go to definition" },
    { keymaps.references, vim.lsp.buf.references, "Find references" },
    { keymaps.hover, vim.lsp.buf.hover, "Hover documentation" },
    { keymaps.rename, vim.lsp.buf.rename, "Rename symbol" },
    { keymaps.code_action, vim.lsp.buf.code_action, "Code action" },
  }
  for _, m in ipairs(mappings) do
    if m[1] and m[1] ~= false then
      vim.keymap.set("n", m[1], m[2], { buffer = buf, desc = "Aptos: " .. m[3] })
    end
  end
end

function M.setup(config)
  local lsp_config = config.lsp
  local cmd = lsp_config.cmd or { "move-analyzer" }

  -- Check if move-analyzer is available
  if vim.fn.executable(cmd[1]) == 0 then
    util.notify(cmd[1] .. " not found on PATH. LSP features disabled.", vim.log.levels.WARN)
    return
  end

  local has_lspconfig, lspconfig = pcall(require, "lspconfig")

  if has_lspconfig then
    -- Path 1: nvim-lspconfig
    lspconfig.move_analyzer.setup({
      cmd = cmd,
      filetypes = { "move" },
      root_dir = function(fname)
        return lspconfig.util.root_pattern("Move.toml")(fname)
      end,
      settings = lsp_config.settings or {},
      on_attach = function(_, bufnr)
        set_keymaps(bufnr, lsp_config.keymaps)
      end,
    })
  elseif vim.fn.has("nvim-0.11") == 1 then
    -- Path 2: native Neovim 0.11+ LSP config
    vim.lsp.config("move_analyzer", {
      cmd = cmd,
      filetypes = { "move" },
      root_markers = { "Move.toml" },
      settings = lsp_config.settings or {},
    })
    vim.lsp.enable("move_analyzer")

    -- Set keymaps via autocmd for native path
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("NvimAptosLsp", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "move_analyzer" then
          set_keymaps(args.buf, lsp_config.keymaps)
        end
      end,
    })
  else
    util.notify("LSP requires nvim-lspconfig or Neovim >= 0.11", vim.log.levels.WARN)
  end
end

return M
