local M = {}

local diagnostic = vim.diagnostic
local api = vim.api

-- Diagnostic configuration for Move
M.setup_diagnostics = function(config)
    local default_config = {
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
            border = "rounded",
            source = "always",
            header = "",
            prefix = "",
        },
    }
    
    config = vim.tbl_deep_extend("force", default_config, config or {})
    
    -- Set diagnostic configuration
    diagnostic.config(config)
    
    -- Setup diagnostic signs
    M.setup_signs()
    
    -- Setup diagnostic keymaps
    M.setup_keymaps()
end

-- Setup diagnostic signs
M.setup_signs = function()
    local signs = {
        { name = "DiagnosticSignError", text = " ", texthl = "DiagnosticSignError" },
        { name = "DiagnosticSignWarn", text = " ", texthl = "DiagnosticSignWarn" },
        { name = "DiagnosticSignHint", text = " ", texthl = "DiagnosticSignHint" },
        { name = "DiagnosticSignInfo", text = " ", texthl = "DiagnosticSignInfo" },
    }
    
    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.texthl, text = sign.text, numhl = "" })
    end
end

-- Setup diagnostic keymaps
M.setup_keymaps = function()
    local opts = { noremap = true, silent = true }
    
    -- Navigate diagnostics
    vim.keymap.set('n', '[d', diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', diagnostic.goto_next, opts)
    
    -- Show diagnostic information
    vim.keymap.set('n', '<leader>e', diagnostic.open_float, opts)
    vim.keymap.set('n', '<leader>q', diagnostic.setloclist, opts)
    
    -- Quick fix
    vim.keymap.set('n', '<leader>f', M.quick_fix, opts)
end

-- Quick fix implementation
M.quick_fix = function()
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
    if #diagnostics == 0 then
        vim.notify("No diagnostics at cursor position", vim.log.levels.INFO)
        return
    end
    
    local diagnostic = diagnostics[1]
    local fixes = M.get_quick_fixes(diagnostic)
    
    if #fixes == 0 then
        vim.notify("No quick fixes available", vim.log.levels.INFO)
        return
    end
    
    -- Show quick fix menu
    M.show_quick_fix_menu(fixes, diagnostic)
end

-- Get quick fixes for diagnostic
M.get_quick_fixes = function(diagnostic)
    local fixes = {}
    
    if diagnostic.category == "syntax" then
        -- Syntax error fixes
        if diagnostic.message:match("expected ';'") then
            table.insert(fixes, {
                title = "Add missing semicolon",
                action = function()
                    local line = vim.api.nvim_get_current_line()
                    vim.api.nvim_set_current_line(line .. ";")
                end
            })
        end
    elseif diagnostic.category == "type" then
        -- Type error fixes
        if diagnostic.message:match("cannot find type") then
            table.insert(fixes, {
                title = "Add missing use statement",
                action = function()
                    -- Implementation for adding use statement
                    vim.notify("Use statement fix not implemented yet", vim.log.levels.INFO)
                end
            })
        end
    end
    
    return fixes
end

-- Show quick fix menu
M.show_quick_fix_menu = function(fixes, diagnostic)
    local items = {}
    for i, fix in ipairs(fixes) do
        table.insert(items, string.format("%d. %s", i, fix.title))
    end
    
    vim.ui.select(items, {
        prompt = "Select quick fix:",
    }, function(choice)
        if choice then
            local index = tonumber(choice:match("^(%d+)"))
            if index and fixes[index] then
                fixes[index].action()
            end
        end
    end)
end

-- Get diagnostic summary
M.get_diagnostic_summary = function()
    local diagnostics = vim.diagnostic.get(0)
    local summary = {}
    
    for _, diag in ipairs(diagnostics) do
        local category = diag.category or "unknown"
        summary[category] = (summary[category] or 0) + 1
    end
    
    return summary
end

-- Show diagnostic summary
M.show_diagnostic_summary = function()
    local summary = M.get_diagnostic_summary()
    local lines = { "Diagnostic Summary:" }
    
    for category, count in pairs(summary) do
        table.insert(lines, string.format("  %s: %d", category, count))
    end
    
    if #lines == 1 then
        table.insert(lines, "  No diagnostics found")
    end
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, {
        title = "Move Diagnostics",
        timeout = 5000,
    })
end

-- Clear all diagnostics
M.clear_all_diagnostics = function()
    vim.diagnostic.set(0, {})
    vim.notify("Cleared all diagnostics", vim.log.levels.INFO)
end

-- Get diagnostics by category
M.get_diagnostics_by_category = function(category)
    local all_diagnostics = vim.diagnostic.get(0)
    local filtered = {}
    
    for _, diag in ipairs(all_diagnostics) do
        if diag.category == category then
            table.insert(filtered, diag)
        end
    end
    
    return filtered
end

-- Navigate to next diagnostic of specific category
M.goto_next_diagnostic_by_category = function(category)
    local diagnostics = M.get_diagnostics_by_category(category)
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    
    for _, diag in ipairs(diagnostics) do
        if diag.lnum > current_line then
            vim.api.nvim_win_set_cursor(0, { diag.lnum + 1, diag.col })
            return
        end
    end
    
    vim.notify("No more " .. category .. " diagnostics", vim.log.levels.INFO)
end

-- Navigate to previous diagnostic of specific category
M.goto_prev_diagnostic_by_category = function(category)
    local diagnostics = M.get_diagnostics_by_category(category)
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    
    for i = #diagnostics, 1, -1 do
        local diag = diagnostics[i]
        if diag.lnum < current_line then
            vim.api.nvim_win_set_cursor(0, { diag.lnum + 1, diag.col })
            return
        end
    end
    
    vim.notify("No previous " .. category .. " diagnostics", vim.log.levels.INFO)
end

return M 