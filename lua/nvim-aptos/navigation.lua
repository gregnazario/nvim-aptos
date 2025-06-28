local M = {}

local api = vim.api

-- Enhanced goto definition for Move
M.goto_definition = function()
    local params = vim.lsp.util.make_position_params()
    
    vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
        if err then
            vim.notify('Error finding definition: ' .. err.message, vim.log.levels.ERROR)
            return
        end
        
        if result and result[1] then
            local uri = result[1].uri
            local range = result[1].range
            
            -- Handle different URI schemes
            if uri:sub(1, 4) == "file" then
                local file_path = vim.uri_to_fname(uri)
                vim.cmd('edit ' .. file_path)
                vim.api.nvim_win_set_cursor(0, {
                    range.start.line + 1,
                    range.start.character
                })
            else
                -- Handle workspace URIs or other schemes
                vim.lsp.util.jump_to_location(result[1])
            end
        else
            vim.notify('Definition not found', vim.log.levels.INFO)
        end
    end)
end

-- Module-aware symbol search
M.find_module_symbols = function()
    local params = {
        query = "",
        kind = vim.lsp.protocol.SymbolKind.Module
    }
    
    vim.lsp.buf_request(0, 'workspace/symbol', params, function(err, result, ctx, config)
        if err then
            vim.notify('Error searching symbols: ' .. err.message, vim.log.levels.ERROR)
            return
        end
        
        -- Display results in quickfix window
        if result and #result > 0 then
            local items = {}
            for _, symbol in ipairs(result) do
                table.insert(items, {
                    filename = vim.uri_to_fname(symbol.location.uri),
                    lnum = symbol.location.range.start.line + 1,
                    col = symbol.location.range.start.character + 1,
                    text = symbol.name
                })
            end
            vim.fn.setqflist(items)
            vim.cmd('copen')
        else
            vim.notify('No symbols found', vim.log.levels.INFO)
        end
    end)
end

-- Resource and struct finder
M.find_resources = function()
    local params = {
        query = "",
        kind = vim.lsp.protocol.SymbolKind.Struct
    }
    
    vim.lsp.buf_request(0, 'workspace/symbol', params, function(err, result, ctx, config)
        if err then return end
        
        -- Filter for resources and structs
        local items = {}
        for _, symbol in ipairs(result or {}) do
            if symbol.name:match("^[A-Z]") then -- Resources typically start with uppercase
                table.insert(items, {
                    filename = vim.uri_to_fname(symbol.location.uri),
                    lnum = symbol.location.range.start.line + 1,
                    col = symbol.location.range.start.character + 1,
                    text = symbol.name
                })
            end
        end
        
        if #items > 0 then
            vim.fn.setqflist(items)
            vim.cmd('copen')
        else
            vim.notify('No resources found', vim.log.levels.INFO)
        end
    end)
end

-- Find function definitions
M.find_functions = function()
    local params = {
        query = "",
        kind = vim.lsp.protocol.SymbolKind.Function
    }
    
    vim.lsp.buf_request(0, 'workspace/symbol', params, function(err, result, ctx, config)
        if err then return end
        
        local items = {}
        for _, symbol in ipairs(result or {}) do
            table.insert(items, {
                filename = vim.uri_to_fname(symbol.location.uri),
                lnum = symbol.location.range.start.line + 1,
                col = symbol.location.range.start.character + 1,
                text = symbol.name
            })
        end
        
        if #items > 0 then
            vim.fn.setqflist(items)
            vim.cmd('copen')
        else
            vim.notify('No functions found', vim.log.levels.INFO)
        end
    end)
end

-- Find use statements
M.find_use_statements = function()
    local syntax = require('nvim-aptos.syntax')
    local nodes = syntax.get_use_statements()
    
    if #nodes == 0 then
        vim.notify('No use statements found', vim.log.levels.INFO)
        return
    end
    
    local items = {}
    for _, node in ipairs(nodes) do
        local range = syntax.get_node_range(node)
        local text = syntax.get_node_text(node)
        local name = syntax.get_node_name(node)
        
        table.insert(items, {
            filename = api.nvim_buf_get_name(0),
            lnum = range.start.line + 1,
            col = range.start.character + 1,
            text = name or table.concat(text, " ")
        })
    end
    
    vim.fn.setqflist(items)
    vim.cmd('copen')
end

-- Jump to module definition in current file
M.goto_module_in_file = function()
    local syntax = require('nvim-aptos.syntax')
    local nodes = syntax.get_module_definitions()
    
    if #nodes == 0 then
        vim.notify('No module definitions found in current file', vim.log.levels.INFO)
        return
    end
    
    -- If only one module, jump to it
    if #nodes == 1 then
        local range = syntax.get_node_range(nodes[1])
        api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
        return
    end
    
    -- If multiple modules, show selection
    local items = {}
    for i, node in ipairs(nodes) do
        local name = syntax.get_node_name(node)
        table.insert(items, string.format("%d. %s", i, name or "unnamed module"))
    end
    
    vim.ui.select(items, {
        prompt = "Select module:",
    }, function(choice)
        if choice then
            local index = tonumber(choice:match("^(%d+)"))
            if index and nodes[index] then
                local range = syntax.get_node_range(nodes[index])
                api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
            end
        end
    end)
end

-- Jump to function definition in current file
M.goto_function_in_file = function()
    local syntax = require('nvim-aptos.syntax')
    local nodes = syntax.get_function_definitions()
    
    if #nodes == 0 then
        vim.notify('No function definitions found in current file', vim.log.levels.INFO)
        return
    end
    
    -- If only one function, jump to it
    if #nodes == 1 then
        local range = syntax.get_node_range(nodes[1])
        api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
        return
    end
    
    -- If multiple functions, show selection
    local items = {}
    for i, node in ipairs(nodes) do
        local name = syntax.get_node_name(node)
        table.insert(items, string.format("%d. %s", i, name or "unnamed function"))
    end
    
    vim.ui.select(items, {
        prompt = "Select function:",
    }, function(choice)
        if choice then
            local index = tonumber(choice:match("^(%d+)"))
            if index and nodes[index] then
                local range = syntax.get_node_range(nodes[index])
                api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
            end
        end
    end)
end

-- Jump to struct/resource definition in current file
M.goto_struct_in_file = function()
    local syntax = require('nvim-aptos.syntax')
    local struct_nodes = syntax.get_struct_definitions()
    local resource_nodes = syntax.get_resource_definitions()
    local nodes = {}
    
    -- Combine struct and resource nodes
    for _, node in ipairs(struct_nodes) do
        table.insert(nodes, { node = node, type = "struct" })
    end
    for _, node in ipairs(resource_nodes) do
        table.insert(nodes, { node = node, type = "resource" })
    end
    
    if #nodes == 0 then
        vim.notify('No struct or resource definitions found in current file', vim.log.levels.INFO)
        return
    end
    
    -- If only one struct/resource, jump to it
    if #nodes == 1 then
        local range = syntax.get_node_range(nodes[1].node)
        api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
        return
    end
    
    -- If multiple structs/resources, show selection
    local items = {}
    for i, item in ipairs(nodes) do
        local name = syntax.get_node_name(item.node)
        table.insert(items, string.format("%d. %s (%s)", i, name or "unnamed", item.type))
    end
    
    vim.ui.select(items, {
        prompt = "Select struct/resource:",
    }, function(choice)
        if choice then
            local index = tonumber(choice:match("^(%d+)"))
            if index and nodes[index] then
                local range = syntax.get_node_range(nodes[index].node)
                api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
            end
        end
    end)
end

return M 