-- Minimal init for testing nvim-aptos
-- Usage: nvim --headless -u tests/minimal_init.lua -c "luafile tests/test_*.lua" -c "qa!"

vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.swapfile = false
vim.opt.backup = false

-- Shared test harness
_G.T = {
  passed = 0,
  failed = 0,
}

function _G.T.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    _G.T.passed = _G.T.passed + 1
    print("  PASS: " .. name)
  else
    _G.T.failed = _G.T.failed + 1
    print("  FAIL: " .. name .. " — " .. tostring(err))
  end
end

function _G.T.eq(expected, actual, msg)
  if expected ~= actual then
    error(string.format("%s: expected %s, got %s", msg or "assertion", vim.inspect(expected), vim.inspect(actual)))
  end
end

function _G.T.neq(val, actual, msg)
  if val == actual then
    error(string.format("%s: expected not %s", msg or "assertion", vim.inspect(val)))
  end
end

function _G.T.is_true(val, msg)
  if not val then
    error(msg or "expected truthy value")
  end
end

function _G.T.is_nil(val, msg)
  if val ~= nil then
    error(string.format("%s: expected nil, got %s", msg or "assertion", vim.inspect(val)))
  end
end

function _G.T.is_type(expected_type, val, msg)
  if type(val) ~= expected_type then
    error(string.format("%s: expected type %s, got %s", msg or "assertion", expected_type, type(val)))
  end
end

function _G.T.summary(suite)
  print(string.format("\n%s: %d passed, %d failed", suite, _G.T.passed, _G.T.failed))
  if _G.T.failed > 0 then
    vim.cmd("cquit!")
  end
end

-- Helper: reset all nvim-aptos modules from package.loaded
function _G.T.reset_modules()
  for k, _ in pairs(package.loaded) do
    if k:match("^nvim%-aptos") then
      package.loaded[k] = nil
    end
  end
end
