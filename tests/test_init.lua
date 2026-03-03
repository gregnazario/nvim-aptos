local test, eq, is_type, is_true, summary = T.test, T.eq, T.is_type, T.is_true, T.summary
local reset = T.reset_modules

print("test_init")

-- ── setup() basic behavior ──────────────────────────────

test("setup: with defaults does not error", function()
  reset()
  require("nvim-aptos").setup()
end)

test("setup: with empty config does not error", function()
  reset()
  require("nvim-aptos").setup({})
end)

test("setup: with nil config does not error", function()
  reset()
  require("nvim-aptos").setup(nil)
end)

test("setup: with all modules disabled does not error", function()
  reset()
  require("nvim-aptos").setup({
    syntax = { enable = false },
    lsp = { enable = false },
    cli = { enable = false },
    prover = { enable = false },
    explorer = { enable = false },
    gas = { enable = false },
  })
end)

-- ── config merging ──────────────────────────────────────

test("setup: merges user config with defaults", function()
  reset()
  local m = require("nvim-aptos")
  m.setup({ cli = { aptos_path = "/custom/aptos" } })
  eq("/custom/aptos", m.config.cli.aptos_path)
  -- Defaults should still be present
  eq(true, m.config.syntax.enable)
  eq(true, m.config.lsp.enable)
end)

test("setup: can override keymaps", function()
  reset()
  local m = require("nvim-aptos")
  m.setup({ lsp = { keymaps = { definition = "<leader>gd" } } })
  eq("<leader>gd", m.config.lsp.keymaps.definition)
  -- Other keymaps should still have defaults
  eq("gr", m.config.lsp.keymaps.references)
end)

test("setup: can disable keymaps with false", function()
  reset()
  local m = require("nvim-aptos")
  m.setup({ lsp = { keymaps = { hover = false } } })
  eq(false, m.config.lsp.keymaps.hover)
end)

test("setup: custom aptos_path propagates", function()
  reset()
  local m = require("nvim-aptos")
  m.setup({
    cli = { aptos_path = "/usr/local/bin/aptos" },
  })
  eq("/usr/local/bin/aptos", m.config.cli.aptos_path)
end)

test("setup: prover keymap override", function()
  reset()
  local m = require("nvim-aptos")
  m.setup({ prover = { keymap = "<leader>mp" } })
  eq("<leader>mp", m.config.prover.keymap)
end)

-- ── public API ──────────────────────────────────────────

test("public API: all functions exist", function()
  reset()
  local m = require("nvim-aptos")
  is_type("function", m.build, "build")
  is_type("function", m.test, "test")
  is_type("function", m.publish, "publish")
  is_type("function", m.prove, "prove")
  is_type("function", m.explore, "explore")
  is_type("function", m.estimate_gas, "estimate_gas")
  is_type("function", m.setup, "setup")
end)

-- ── module loading ──────────────────────────────────────

test("module: util loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.util")
  is_true(ok, "util should load")
  is_type("function", mod.find_project_root)
  is_type("function", mod.run_async)
  is_type("function", mod.open_float)
  is_type("function", mod.parse_json)
  is_type("function", mod.notify)
end)

test("module: health loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.health")
  is_true(ok, "health should load")
  is_type("function", mod.check)
end)

test("module: syntax loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.syntax")
  is_true(ok, "syntax should load")
  is_type("function", mod.setup)
  is_type("function", mod.get_node_at_cursor)
  is_type("function", mod.get_node_text)
  is_type("function", mod.query_nodes)
end)

test("module: lsp loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.lsp")
  is_true(ok, "lsp should load")
  is_type("function", mod.setup)
end)

test("module: cli loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.cli")
  is_true(ok, "cli should load")
  is_type("function", mod.setup)
  is_type("function", mod.build)
  is_type("function", mod.test)
  is_type("function", mod.publish)
  is_type("function", mod.init_project)
  is_type("function", mod.account)
  is_type("function", mod.network)
end)

test("module: prover loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.prover")
  is_true(ok, "prover should load")
  is_type("function", mod.setup)
  is_type("function", mod.prove)
end)

test("module: explorer loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.explorer")
  is_true(ok, "explorer should load")
  is_type("function", mod.setup)
  is_type("function", mod.explore)
end)

test("module: gas loads independently", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.gas")
  is_true(ok, "gas should load")
  is_type("function", mod.setup)
  is_type("function", mod.estimate)
end)

-- ── partial failure resilience ──────────────────────────

test("setup: continues if one module fails", function()
  reset()
  -- Sabotage the syntax module temporarily
  package.preload["nvim-aptos.syntax"] = function()
    error("intentional test error")
  end
  -- Should not throw — pcall catches module init failures
  local ok = pcall(require("nvim-aptos").setup, {})
  is_true(ok, "setup should succeed even if a module fails")
  package.preload["nvim-aptos.syntax"] = nil
end)

summary("test_init")
