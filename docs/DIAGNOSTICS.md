# Error Highlighting and Diagnostics Plan

## Overview

This document outlines the implementation of comprehensive error highlighting and diagnostic features for the Aptos Move language, including real-time error detection, compilation error display, and warning highlighting.

## Diagnostic Features

### Core Diagnostic Features
1. **Real-time Error Detection** - Show errors as you type
2. **Compilation Error Display** - Display build errors in the editor
3. **Warning Highlighting** - Highlight warnings and suggestions
4. **Error Navigation** - Quick navigation between errors
5. **Error Context** - Detailed error information and suggestions

### Advanced Features
1. **Error Categories** - Different highlighting for different error types
2. **Quick Fixes** - Automatic error correction suggestions
3. **Error History** - Track error patterns and frequency
4. **Custom Error Rules** - User-defined error patterns
5. **Performance Diagnostics** - Highlight performance issues

## Implementation Strategy

### Phase 1: Basic Diagnostic Integration

#### File: `lua/nvim-aptos/diagnostics.lua`

```lua
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

return M
```

### Phase 2: Move-Specific Error Handling

#### File: `lua/nvim-aptos/diagnostics/move_errors.lua`

```lua
local M = {}

-- Move error categories
M.error_categories = {
    SYNTAX = "syntax",
    TYPE = "type",
    BORROW = "borrow",
    RESOURCE = "resource",
    MODULE = "module",
    COMPILATION = "compilation",
    RUNTIME = "runtime",
}

-- Move error patterns
M.error_patterns = {
    -- Syntax errors
    {
        pattern = "expected '([^']+)' but found '([^']+)'",
        category = M.error_categories.SYNTAX,
        severity = vim.diagnostic.severity.ERROR,
    },
    {
        pattern = "unexpected token '([^']+)'",
        category = M.error_categories.SYNTAX,
        severity = vim.diagnostic.severity.ERROR,
    },
    
    -- Type errors
    {
        pattern = "type mismatch: expected ([^,]+), found ([^,]+)",
        category = M.error_categories.TYPE,
        severity = vim.diagnostic.severity.ERROR,
    },
    {
        pattern = "cannot find type '([^']+)'",
        category = M.error_categories.TYPE,
        severity = vim.diagnostic.severity.ERROR,
    },
    
    -- Borrow checker errors
    {
        pattern = "cannot borrow ([^,]+) as mutable because it is also borrowed as immutable",
        category = M.error_categories.BORROW,
        severity = vim.diagnostic.severity.ERROR,
    },
    {
        pattern = "use of moved value",
        category = M.error_categories.BORROW,
        severity = vim.diagnostic.severity.ERROR,
    },
    
    -- Resource errors
    {
        pattern = "resource '([^']+)' not found",
        category = M.error_categories.RESOURCE,
        severity = vim.diagnostic.severity.ERROR,
    },
    {
        pattern = "cannot destroy resource '([^']+)'",
        category = M.error_categories.RESOURCE,
        severity = vim.diagnostic.severity.ERROR,
    },
    
    -- Module errors
    {
        pattern = "module '([^']+)' not found",
        category = M.error_categories.MODULE,
        severity = vim.diagnostic.severity.ERROR,
    },
    {
        pattern = "function '([^']+)' not found in module",
        category = M.error_categories.MODULE,
        severity = vim.diagnostic.severity.ERROR,
    },
}

-- Parse Move compilation output
M.parse_compilation_output = function(output)
    local diagnostics = {}
    
    for _, line in ipairs(output) do
        for _, pattern in ipairs(M.error_patterns) do
            local matches = { line:match(pattern.pattern) }
            if #matches > 0 then
                local diagnostic = M.create_diagnostic(line, pattern, matches)
                if diagnostic then
                    table.insert(diagnostics, diagnostic)
                end
            end
        end
    end
    
    return diagnostics
end

-- Create diagnostic from error pattern
M.create_diagnostic = function(line, pattern, matches)
    -- Extract line and column information from the line
    local line_num, col_num = line:match("(%d+):(%d+)")
    if not line_num then
        return nil
    end
    
    return {
        lnum = tonumber(line_num) - 1, -- Convert to 0-based indexing
        col = tonumber(col_num) - 1,
        severity = pattern.severity,
        message = line,
        source = "move_compiler",
        category = pattern.category,
    }
end

return M
```

### Phase 3: Real-time Error Detection

#### File: `lua/nvim-aptos/diagnostics/realtime.lua`

```lua
local M = {}

local timer = vim.loop.new_timer()
local debounce_time = 500 -- milliseconds

-- Real-time error checking
M.setup_realtime_checking = function()
    local group = api.nvim_create_augroup("MoveRealtimeDiagnostics", { clear = true })
    
    api.nvim_create_autocmd("TextChanged", {
        group = group,
        pattern = "*.move",
        callback = function()
            M.debounced_check()
        end,
    })
    
    api.nvim_create_autocmd("TextChangedI", {
        group = group,
        pattern = "*.move",
        callback = function()
            M.debounced_check()
        end,
    })
end

-- Debounced error checking
M.debounced_check = function()
    if timer then
        timer:stop()
    end
    
    timer:start(debounce_time, 0, vim.schedule_wrap(function()
        M.check_current_file()
    end))
end

-- Check current file for errors
M.check_current_file = function()
    local bufnr = api.nvim_get_current_buf()
    local filename = api.nvim_buf_get_name(bufnr)
    
    if not filename:match("%.move$") then
        return
    end
    
    -- Run move-analyzer check
    M.run_move_check(filename, bufnr)
end

-- Run move-analyzer check
M.run_move_check = function(filename, bufnr)
    local job = vim.fn.jobstart({ "move-analyzer", "check", filename }, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                -- Clear diagnostics if no errors
                vim.diagnostic.set(bufnr, {})
            else
                -- Parse and display errors
                local diagnostics = M.parse_compilation_output(stderr)
                vim.diagnostic.set(bufnr, diagnostics)
            end
        end,
    })
end

return M
```

### Phase 4: Enhanced Error Display

#### File: `lua/nvim-aptos/diagnostics/display.lua`

```lua
local M = {}

-- Custom diagnostic display
M.setup_custom_display = function()
    -- Override default diagnostic float
    vim.diagnostic.open_float = M.custom_open_float
    
    -- Setup error highlighting
    M.setup_error_highlighting()
end

-- Custom diagnostic float
M.custom_open_float = function(opts, bufnr)
    opts = opts or {}
    bufnr = bufnr or 0
    
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })
    if #diagnostics == 0 then
        return
    end
    
    local lines = {}
    local highlights = {}
    
    for i, diagnostic in ipairs(diagnostics) do
        local prefix = string.format("[%s] ", diagnostic.source or "move")
        local message = diagnostic.message
        
        -- Add category information
        if diagnostic.category then
            prefix = prefix .. string.format("(%s) ", diagnostic.category)
        end
        
        table.insert(lines, prefix .. message)
        
        -- Add highlighting for category
        if diagnostic.category then
            table.insert(highlights, {
                line = i - 1,
                col_start = #prefix - #diagnostic.category - 3,
                col_end = #prefix - 1,
                hl_group = "DiagnosticCategory" .. diagnostic.category:upper(),
            })
        end
    end
    
    local float_opts = {
        border = opts.border or "rounded",
        source = "always",
        header = "",
        prefix = "",
        focusable = false,
        style = "minimal",
    }
    
    local float_bufnr, float_winnr = vim.diagnostic.open_float(float_opts, {
        scope = "cursor",
        header = "",
        prefix = "",
    })
    
    -- Apply custom highlighting
    if float_bufnr and #highlights > 0 then
        for _, highlight in ipairs(highlights) do
            api.nvim_buf_add_highlight(float_bufnr, -1, highlight.hl_group, highlight.line, highlight.col_start, highlight.col_end)
        end
    end
    
    return float_bufnr, float_winnr
end

-- Setup error highlighting
M.setup_error_highlighting = function()
    local highlight_groups = {
        DiagnosticCategorySyntax = { fg = "#ff6b6b" },
        DiagnosticCategoryType = { fg = "#4ecdc4" },
        DiagnosticCategoryBorrow = { fg = "#45b7d1" },
        DiagnosticCategoryResource = { fg = "#96ceb4" },
        DiagnosticCategoryModule = { fg = "#feca57" },
        DiagnosticCategoryCompilation = { fg = "#ff9ff3" },
        DiagnosticCategoryRuntime = { fg = "#ff9f43" },
    }
    
    for group, settings in pairs(highlight_groups) do
        api.nvim_set_hl(0, group, settings)
    end
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

return M
```

### Phase 5: Error Navigation and Management

#### File: `lua/nvim-aptos/diagnostics/navigation.lua`

```lua
local M = {}

-- Error navigation commands
M.setup_navigation = function()
    -- Navigate to next error of specific category
    vim.keymap.set('n', '<leader>]s', function() M.goto_next_error("syntax") end, { noremap = true })
    vim.keymap.set('n', '<leader>]t', function() M.goto_next_error("type") end, { noremap = true })
    vim.keymap.set('n', '<leader>]b', function() M.goto_next_error("borrow") end, { noremap = true })
    vim.keymap.set('n', '<leader>]r', function() M.goto_next_error("resource") end, { noremap = true })
    
    -- Navigate to previous error of specific category
    vim.keymap.set('n', '<leader>[s', function() M.goto_prev_error("syntax") end, { noremap = true })
    vim.keymap.set('n', '<leader>[t', function() M.goto_prev_error("type") end, { noremap = true })
    vim.keymap.set('n', '<leader>[b', function() M.goto_prev_error("borrow") end, { noremap = true })
    vim.keymap.set('n', '<leader>[r', function() M.goto_prev_error("resource") end, { noremap = true })
    
    -- Show error summary
    vim.keymap.set('n', '<leader>es', M.show_error_summary, { noremap = true })
    
    -- Clear all diagnostics
    vim.keymap.set('n', '<leader>ec', M.clear_all_diagnostics, { noremap = true })
end

-- Navigate to next error of specific category
M.goto_next_error = function(category)
    local diagnostics = vim.diagnostic.get(0)
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.category == category and diagnostic.lnum > current_line then
            vim.api.nvim_win_set_cursor(0, { diagnostic.lnum + 1, diagnostic.col })
            return
        end
    end
    
    vim.notify("No more " .. category .. " errors", vim.log.levels.INFO)
end

-- Navigate to previous error of specific category
M.goto_prev_error = function(category)
    local diagnostics = vim.diagnostic.get(0)
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    
    for i = #diagnostics, 1, -1 do
        local diagnostic = diagnostics[i]
        if diagnostic.category == category and diagnostic.lnum < current_line then
            vim.api.nvim_win_set_cursor(0, { diagnostic.lnum + 1, diagnostic.col })
            return
        end
    end
    
    vim.notify("No previous " .. category .. " errors", vim.log.levels.INFO)
end

-- Show error summary
M.show_error_summary = function()
    local diagnostics = vim.diagnostic.get(0)
    local summary = {}
    
    for _, diagnostic in ipairs(diagnostics) do
        local category = diagnostic.category or "unknown"
        summary[category] = (summary[category] or 0) + 1
    end
    
    local lines = { "Error Summary:" }
    for category, count in pairs(summary) do
        table.insert(lines, string.format("  %s: %d", category, count))
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

return M
```

## Configuration Options

### User Configuration

```lua
require('nvim-aptos').setup({
    diagnostics = {
        enable = true,
        realtime = true,
        debounce_time = 500,
        display = {
            virtual_text = true,
            signs = true,
            underline = true,
            float = {
                border = "rounded",
                source = "always",
            },
        },
        categories = {
            syntax = { fg = "#ff6b6b" },
            type = { fg = "#4ecdc4" },
            borrow = { fg = "#45b7d1" },
            resource = { fg = "#96ceb4" },
            module = { fg = "#feca57" },
        },
        quick_fixes = {
            enable = true,
            auto_apply = false,
        },
    }
})
```

## Testing Strategy

### Diagnostic Feature Tests

1. **Error Detection**
   - Test syntax error detection
   - Test type error detection
   - Test borrow checker error detection
   - Test resource error detection

2. **Error Display**
   - Test error highlighting
   - Test error navigation
   - Test error categories
   - Test quick fixes

3. **Performance**
   - Test real-time checking performance
   - Test large file handling
   - Test memory usage

### Integration Testing

1. **LSP Integration**
   - Test LSP diagnostic integration
   - Test diagnostic override
   - Test diagnostic merging

2. **Compiler Integration**
   - Test move-analyzer integration
   - Test compilation error parsing
   - Test build error display

## Future Enhancements

1. **Advanced Quick Fixes**
   - Automatic import addition
   - Type annotation suggestions
   - Resource management fixes

2. **Error Prevention**
   - Predictive error detection
   - Code style suggestions
   - Performance warnings

3. **Error Analytics**
   - Error frequency tracking
   - Common error patterns
   - Error resolution suggestions 