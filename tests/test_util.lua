local test, eq, is_nil, is_type, is_true, summary = T.test, T.eq, T.is_nil, T.is_type, T.is_true, T.summary

local util = require("nvim-aptos.util")

print("test_util")

-- ── parse_json ──────────────────────────────────────────

test("parse_json: valid object", function()
  local result = util.parse_json('{"key": "value"}')
  is_type("table", result)
  eq("value", result.key)
end)

test("parse_json: valid array", function()
  local result = util.parse_json('[1, 2, 3]')
  is_type("table", result)
  eq(3, #result)
  eq(2, result[2])
end)

test("parse_json: nested object", function()
  local result = util.parse_json('{"a": {"b": 42}}')
  is_type("table", result)
  eq(42, result.a.b)
end)

test("parse_json: empty object", function()
  local result = util.parse_json("{}")
  is_type("table", result)
end)

test("parse_json: empty array", function()
  local result = util.parse_json("[]")
  is_type("table", result)
  eq(0, #result)
end)

test("parse_json: invalid JSON returns nil + error", function()
  local result, err = util.parse_json("not json")
  is_nil(result)
  is_type("string", err, "error should be a string")
end)

test("parse_json: empty string returns nil + error", function()
  local result, err = util.parse_json("")
  is_nil(result)
  is_type("string", err)
end)

test("parse_json: numbers", function()
  local result = util.parse_json("42")
  eq(42, result)
end)

test("parse_json: boolean", function()
  local result = util.parse_json("true")
  eq(true, result)
end)

test("parse_json: string value", function()
  local result = util.parse_json('"hello"')
  eq("hello", result)
end)

-- ── find_project_root ───────────────────────────────────

test("find_project_root: returns nil when no Move.toml", function()
  local root = util.find_project_root("/tmp")
  is_nil(root)
end)

test("find_project_root: returns nil for filesystem root", function()
  local root = util.find_project_root("/")
  is_nil(root)
end)

-- Create a temp directory with Move.toml to test positive case
test("find_project_root: finds Move.toml in current dir", function()
  local tmpdir = vim.fn.tempname()
  vim.fn.mkdir(tmpdir, "p")
  local f = io.open(tmpdir .. "/Move.toml", "w")
  f:write("[package]\n")
  f:close()

  local root = util.find_project_root(tmpdir)
  eq(tmpdir, root)

  os.remove(tmpdir .. "/Move.toml")
  vim.fn.delete(tmpdir, "d")
end)

test("find_project_root: finds Move.toml in parent dir", function()
  local tmpdir = vim.fn.tempname()
  local subdir = tmpdir .. "/sources"
  vim.fn.mkdir(subdir, "p")
  local f = io.open(tmpdir .. "/Move.toml", "w")
  f:write("[package]\n")
  f:close()

  local root = util.find_project_root(subdir)
  eq(tmpdir, root)

  os.remove(tmpdir .. "/Move.toml")
  vim.fn.delete(subdir, "d")
  vim.fn.delete(tmpdir, "d")
end)

-- ── notify ──────────────────────────────────────────────

test("notify: does not error", function()
  -- Just ensure it doesn't throw
  util.notify("test message")
  util.notify("test warn", vim.log.levels.WARN)
  util.notify("test error", vim.log.levels.ERROR)
end)

-- ── open_float ──────────────────────────────────────────

test("open_float: creates buffer and window", function()
  local lines = { "line 1", "line 2", "line 3" }
  local buf, win = util.open_float(lines)
  is_true(vim.api.nvim_buf_is_valid(buf), "buf should be valid")
  is_true(vim.api.nvim_win_is_valid(win), "win should be valid")

  -- Check content
  local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  eq(3, #content)
  eq("line 1", content[1])

  -- Check buffer options
  eq(false, vim.bo[buf].modifiable)

  -- Cleanup
  vim.api.nvim_win_close(win, true)
end)

test("open_float: with title", function()
  local buf, win = util.open_float({ "hello" }, { title = "Test" })
  is_true(vim.api.nvim_win_is_valid(win))
  vim.api.nvim_win_close(win, true)
end)

test("open_float: with filetype", function()
  local buf, win = util.open_float({ '{"a": 1}' }, { filetype = "json" })
  eq("json", vim.bo[buf].filetype)
  vim.api.nvim_win_close(win, true)
end)

test("open_float: empty lines", function()
  local buf, win = util.open_float({})
  is_true(vim.api.nvim_buf_is_valid(buf))
  vim.api.nvim_win_close(win, true)
end)

-- ── run_async ───────────────────────────────────────────

test("run_async: callback is a function", function()
  is_type("function", util.run_async)
end)

summary("test_util")
