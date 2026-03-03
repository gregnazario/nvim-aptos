local M = {}

function M.check()
  vim.health.start("nvim-aptos")

  -- Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 required")
  end

  -- move-analyzer
  if vim.fn.executable("move-analyzer") == 1 then
    vim.health.ok("move-analyzer found on PATH")
  else
    vim.health.warn("move-analyzer not found", {
      "Install from https://github.com/aptos-labs/aptos-core",
      "cargo install --git https://github.com/aptos-labs/aptos-core move-analyzer",
    })
  end

  -- aptos CLI
  if vim.fn.executable("aptos") == 1 then
    vim.health.ok("aptos CLI found on PATH")
  else
    vim.health.warn("aptos CLI not found", {
      "Install from https://aptos.dev/tools/aptos-cli/",
    })
  end

  -- tree-sitter parser
  local ts_ok = pcall(vim.treesitter.language.inspect, "move_on_aptos")
  if ts_ok then
    vim.health.ok("tree-sitter parser for move_on_aptos installed")
  else
    vim.health.warn("tree-sitter parser for move_on_aptos not installed", {
      "Install with :TSInstall move_on_aptos (nvim-treesitter)",
      "Or build from https://github.com/aptos-labs/tree-sitter-move-on-aptos",
    })
  end

  -- lspconfig OR Neovim >= 0.11
  local has_lspconfig = pcall(require, "lspconfig")
  local has_native_lsp = vim.fn.has("nvim-0.11") == 1
  if has_lspconfig then
    vim.health.ok("nvim-lspconfig available")
  elseif has_native_lsp then
    vim.health.ok("Neovim >= 0.11 (native LSP config)")
  else
    vim.health.warn("No LSP config method available", {
      "Install nvim-lspconfig or upgrade to Neovim >= 0.11",
    })
  end
end

return M
