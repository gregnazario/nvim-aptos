local M = {}

local api = vim.api

-- Setup Tree-sitter for Move
M.setup_treesitter = function()
    local status_ok, configs = pcall(require, 'nvim-treesitter.configs')
    if not status_ok then
        vim.notify("nvim-treesitter not found", vim.log.levels.WARN)
        return
    end
    
    configs.setup({
        ensure_installed = { "move" },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = true,
        },
        fold = {
            enable = true,
            method = "expr",
        },
    })
end

-- Setup traditional Vim syntax
M.setup_traditional = function()
    -- This will be handled by the syntax/move.vim file
    -- Just ensure filetype detection is set up
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "move",
        callback = function()
            -- Enable traditional syntax highlighting
            vim.cmd("syntax enable")
        end,
    })
end

-- Setup custom highlight groups for Move
M.setup_highlights = function()
    local highlights = {
        -- Move-specific highlights
        ["@move.keyword"] = { fg = "#C586C0" },
        ["@move.type"] = { fg = "#4EC9B0" },
        ["@move.function"] = { fg = "#DCDCAA" },
        ["@move.address"] = { fg = "#CE9178" },
        ["@move.resource"] = { fg = "#569CD6" },
        ["@move.module"] = { fg = "#4FC1FF" },
        ["@move.struct"] = { fg = "#569CD6" },
        ["@move.constant"] = { fg = "#4FC1FF" },
        ["@move.string"] = { fg = "#CE9178" },
        ["@move.number"] = { fg = "#B5CEA8" },
        ["@move.boolean"] = { fg = "#569CD6" },
        ["@move.operator"] = { fg = "#D4D4D4" },
        ["@move.comment"] = { fg = "#6A9955", italic = true },
        
        -- Traditional syntax groups
        ["moveKeyword"] = { fg = "#C586C0" },
        ["moveType"] = { fg = "#4EC9B0" },
        ["moveBuiltin"] = { fg = "#DCDCAA" },
        ["moveAddress"] = { fg = "#CE9178" },
        ["moveString"] = { fg = "#CE9178" },
        ["moveNumber"] = { fg = "#B5CEA8" },
        ["moveBoolean"] = { fg = "#569CD6" },
        ["moveComment"] = { fg = "#6A9955", italic = true },
    }
    
    for group, settings in pairs(highlights) do
        api.nvim_set_hl(0, group, settings)
    end
end

-- Setup syntax-aware folding
M.setup_folding = function()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "move",
        callback = function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
            vim.opt_local.foldlevelstart = 1
        end,
    })
end

-- Get syntax tree for current buffer
M.get_syntax_tree = function()
    local status_ok, ts = pcall(require, 'nvim-treesitter')
    if not status_ok then
        return nil
    end
    
    local bufnr = api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, "move")
    if not parser then
        return nil
    end
    
    return parser:parse()[1]:root()
end

-- Get node at cursor position
M.get_node_at_cursor = function()
    local status_ok, ts = pcall(require, 'nvim-treesitter.ts_utils')
    if not status_ok then
        return nil
    end
    
    return ts.get_node_at_cursor()
end

-- Get node type at cursor position
M.get_node_type_at_cursor = function()
    local node = M.get_node_at_cursor()
    if not node then
        return nil
    end
    
    return node:type()
end

-- Check if cursor is on a specific node type
M.is_cursor_on_node_type = function(node_type)
    local current_type = M.get_node_type_at_cursor()
    return current_type == node_type
end

-- Get all nodes of a specific type in the buffer
M.get_nodes_by_type = function(node_type)
    local status_ok, query = pcall(require, 'nvim-treesitter.query')
    if not status_ok then
        return {}
    end
    
    local bufnr = api.nvim_get_current_buf()
    local query_string = string.format("(%s) @node", node_type)
    local parsed_query = query.parse_query("move", query_string)
    
    if not parsed_query then
        return {}
    end
    
    local nodes = {}
    local tree = M.get_syntax_tree()
    if not tree then
        return nodes
    end
    
    for _, captures, _ in parsed_query:iter_matches(tree, bufnr) do
        for _, node in ipairs(captures) do
            table.insert(nodes, node)
        end
    end
    
    return nodes
end

-- Get function definitions in the buffer
M.get_function_definitions = function()
    return M.get_nodes_by_type("function_definition")
end

-- Get module definitions in the buffer
M.get_module_definitions = function()
    return M.get_nodes_by_type("module_definition")
end

-- Get struct definitions in the buffer
M.get_struct_definitions = function()
    return M.get_nodes_by_type("struct_definition")
end

-- Get resource definitions in the buffer
M.get_resource_definitions = function()
    return M.get_nodes_by_type("resource_definition")
end

-- Get use statements in the buffer
M.get_use_statements = function()
    return M.get_nodes_by_type("use_statement")
end

-- Get the name of a node
M.get_node_name = function(node)
    if not node then
        return nil
    end
    
    local status_ok, ts = pcall(require, 'nvim-treesitter.ts_utils')
    if not status_ok then
        return nil
    end
    
    return ts.get_node_text(node)[1]
end

-- Get the full text of a node
M.get_node_text = function(node)
    if not node then
        return nil
    end
    
    local status_ok, ts = pcall(require, 'nvim-treesitter.ts_utils')
    if not status_ok then
        return nil
    end
    
    return ts.get_node_text(node)
end

-- Get the range of a node
M.get_node_range = function(node)
    if not node then
        return nil
    end
    
    local start_row, start_col, end_row, end_col = node:range()
    return {
        start = { line = start_row, character = start_col },
        ["end"] = { line = end_row, character = end_col }
    }
end

-- Check if a node contains the cursor position
M.node_contains_cursor = function(node)
    if not node then
        return false
    end
    
    local cursor_pos = api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1] - 1  -- Convert to 0-based
    local cursor_col = cursor_pos[2]
    
    local start_row, start_col, end_row, end_col = node:range()
    
    if cursor_line < start_row or cursor_line > end_row then
        return false
    end
    
    if cursor_line == start_row and cursor_col < start_col then
        return false
    end
    
    if cursor_line == end_row and cursor_col > end_col then
        return false
    end
    
    return true
end

return M 