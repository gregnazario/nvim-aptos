local test, eq, is_nil, is_type, is_true, summary = T.test, T.eq, T.is_nil, T.is_type, T.is_true, T.summary
local reset = T.reset_modules

print("test_cli")

-- ── module loading ──────────────────────────────────────

test("cli module loads", function()
  reset()
  local ok, mod = pcall(require, "nvim-aptos.cli")
  is_true(ok, "cli should load")
  is_type("table", mod)
end)

test("cli.setup: valid config", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local ok, err = pcall(cli.setup, {
    cli = {
      aptos_path = "aptos",
      keymaps = {
        build = "<leader>ab",
        test = "<leader>at",
        publish = "<leader>ap",
      },
    },
  })
  is_true(ok, tostring(err))
end)

test("cli.setup: custom aptos path", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local ok = pcall(cli.setup, {
    cli = {
      aptos_path = "/usr/local/bin/aptos",
      keymaps = { build = "<leader>ab", test = "<leader>at", publish = "<leader>ap" },
    },
  })
  is_true(ok)
end)

-- ── error parser ────────────────────────────────────────

test("parse_errors: empty input", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local entries = cli._parse_errors("")
  eq(0, #entries)
end)

test("parse_errors: no errors in output", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local entries = cli._parse_errors("Build succeeded!\nDone.")
  eq(0, #entries)
end)

test("parse_errors: single error with location", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local output = [[
error[E01002]: unexpected token
   ┌─ sources/main.move:10:5
   │
10 │     let x = ;
   │             ^ Expected an expression
]]
  local entries = cli._parse_errors(output)
  eq(1, #entries)
  eq("sources/main.move", entries[1].filename)
  eq(10, entries[1].lnum)
  eq(5, entries[1].col)
  eq("unexpected token", entries[1].text)
end)

test("parse_errors: multiple errors", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local output = [[
error[E04001]: type mismatch
   ┌─ sources/main.move:15:12
   │
15 │     let x: u64 = true;
   │            ^^^ Expected u64

error[E01002]: unexpected token
   ┌─ sources/main.move:20:1
   │
20 │ }
   │ ^ unexpected '}'
]]
  local entries = cli._parse_errors(output)
  eq(2, #entries)
  eq(15, entries[1].lnum)
  eq(12, entries[1].col)
  eq("type mismatch", entries[1].text)
  eq(20, entries[2].lnum)
  eq(1, entries[2].col)
  eq("unexpected token", entries[2].text)
end)

test("parse_errors: error without code bracket", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local output = [[
error: cannot find module
   ┌─ sources/main.move:3:5
]]
  local entries = cli._parse_errors(output)
  eq(1, #entries)
  eq("cannot find module", entries[1].text)
end)

test("parse_errors: ├─ continuation marker", function()
  reset()
  local cli = require("nvim-aptos.cli")
  local output = [[
error[E06001]: unused value
   ┌─ sources/main.move:10:9
   │
10 │     let x = 5;
   │         ^ unused
   ├─ sources/other.move:20:3
   │
]]
  local entries = cli._parse_errors(output)
  -- Should have at least the first error
  is_true(#entries >= 1, "should parse at least one entry")
  eq("sources/main.move", entries[1].filename)
end)

-- ── prover error parser ─────────────────────────────────

test("prover parse: empty input", function()
  reset()
  local prover = require("nvim-aptos.prover")
  local entries = prover._parse_prover_output("")
  eq(0, #entries)
end)

test("prover parse: verification error with location", function()
  reset()
  local prover = require("nvim-aptos.prover")
  local output = [[
error: verification failed
   ┌─ sources/main.move:25:5
   │
25 │     ensures result > 0;
   │     ^^^^^^^^^^^^^^^^^^^ post-condition not satisfied
]]
  local entries = prover._parse_prover_output(output)
  eq(1, #entries)
  eq("sources/main.move", entries[1].filename)
  eq(25, entries[1].lnum)
  eq(5, entries[1].col)
  eq("E", entries[1].type)
end)

-- ── ftdetect ────────────────────────────────────────────

test("ftdetect: .move files get move filetype", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "test.move")
  vim.api.nvim_set_current_buf(buf)
  vim.cmd("doautocmd BufRead")
  eq("move", vim.bo[buf].filetype)
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- ── ftplugin ────────────────────────────────────────────

test("ftplugin: sets buffer options for move files", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "ftplugin_test.move")
  vim.api.nvim_set_current_buf(buf)
  vim.cmd("doautocmd BufRead")
  -- ftplugin should have fired
  eq(4, vim.bo[buf].tabstop)
  eq(4, vim.bo[buf].shiftwidth)
  eq(true, vim.bo[buf].expandtab)
  eq("// %s", vim.bo[buf].commentstring)
  vim.api.nvim_buf_delete(buf, { force = true })
end)

summary("test_cli")
