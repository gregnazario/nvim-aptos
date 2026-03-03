local M = {}

function M.setup(config)
  -- Register the parser for the move filetype
  vim.treesitter.language.register("move_on_aptos", "move")

  local group = vim.api.nvim_create_augroup("NvimAptosSyntax", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "move",
    callback = function(args)
      local buf = args.buf
      -- Start tree-sitter highlighting
      local ok, err = pcall(vim.treesitter.start, buf, "move_on_aptos")
      if not ok then
        -- Parser not installed — silently skip
        return
      end

      -- Tree-sitter folds
      if config.syntax.folds then
        vim.wo[0][0].foldmethod = "expr"
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo[0][0].foldenable = false
      end
    end,
  })
end

--- Get the tree-sitter node under the cursor
---@return TSNode|nil
function M.get_node_at_cursor()
  local ok, node = pcall(vim.treesitter.get_node)
  if ok then
    return node
  end
  return nil
end

--- Get text of a tree-sitter node
---@param node TSNode
---@param buf? integer
---@return string
function M.get_node_text(node, buf)
  return vim.treesitter.get_node_text(node, buf or 0)
end

--- Run a tree-sitter query and return matches
---@param query_string string
---@param buf? integer
---@return table[] list of {node, capture_name}
function M.query_nodes(query_string, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local lang = "move_on_aptos"
  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return {}
  end

  local trees = parser:parse()
  if not trees or not trees[1] then
    return {}
  end

  local root = trees[1]:root()
  local query = vim.treesitter.query.parse(lang, query_string)
  local results = {}
  for id, node in query:iter_captures(root, buf) do
    table.insert(results, { node = node, name = query.captures[id] })
  end
  return results
end

return M
