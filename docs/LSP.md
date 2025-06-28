# Language Server Protocol (LSP) Integration Plan

## Overview

This document outlines the implementation of LSP integration for the Aptos Move language, enabling advanced code navigation features including jump to definition, code completion, hover information, and more.

## LSP Features for Move

### Core Navigation Features
1. **Jump to Definition** - Navigate to function, struct, resource, and module definitions
2. **Go to References** - Find all usages of a symbol
3. **Symbol Search** - Search for symbols across the workspace
4. **Hover Information** - Display type information and documentation
5. **Code Completion** - Intelligent autocomplete for Move constructs

### Advanced Features
1. **Signature Help** - Function parameter information
2. **Code Actions** - Refactoring and quick fixes
3. **Document Symbols** - Outline view of file structure
4. **Workspace Symbols** - Global symbol search
5. **Semantic Tokens** - Enhanced syntax highlighting

## Implementation Strategy

### Phase 1: LSP Client Setup

#### File: `lua/nvim-aptos/lsp.lua`

```lua
local M = {}

local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- LSP configuration for Move
M.setup_lsp = function(config)
    local default_config = {
        capabilities = capabilities,
        on_attach = M.on_attach,
        settings = {
            move = {
                -- Move-specific LSP settings
                diagnostics = {
                    enable = true,
                    experimental = true,
                },
                hover = {
                    enable = true,
                },
                completion = {
                    enable = true,
                },
            }
        }
    }
    
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", default_config, config or {})
    
    -- Setup LSP for Move files
    lspconfig.move_analyzer.setup(config)
end

-- LSP attach function
M.on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, silent = true }
    
    -- Key mappings for LSP features
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol, opts)
    vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, opts)
    
    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
            vim.lsp.buf.format()
        end,
    })
end

return M
```

### Phase 2: Move Language Server Integration

#### Supported LSP Servers

1. **Move Analyzer** (Primary)
   - Official Move language server
   - Full Move language support
   - Aptos-specific features

2. **Move-analyzer** (Alternative)
   - Community-driven LSP server
   - Enhanced error reporting
   - Custom diagnostics

#### File: `lua/nvim-aptos/lsp/servers.lua`

```lua
local M = {}

-- Move Analyzer configuration
M.move_analyzer = {
    cmd = { "move-analyzer" },
    filetypes = { "move" },
    root_dir = function(fname)
        return require('lspconfig.util').root_pattern("Move.toml")(fname)
    end,
    settings = {
        move = {
            -- Analyzer-specific settings
            diagnostics = {
                enable = true,
                experimental = true,
            },
            hover = {
                enable = true,
            },
            completion = {
                enable = true,
            },
            inlayHints = {
                enable = true,
            },
        }
    }
}

-- Custom LSP server setup
M.setup_custom_server = function()
    local config = require('lspconfig.configs')
    
    if not config.move_analyzer then
        config.move_analyzer = {
            default_config = {
                cmd = { "move-analyzer" },
                filetypes = { "move" },
                root_dir = function(fname)
                    return require('lspconfig.util').root_pattern("Move.toml")(fname)
                end,
                settings = {},
            },
        }
    end
end

return M
```

### Phase 3: Enhanced Navigation Features

#### File: `lua/nvim-aptos/navigation.lua`

```lua
local M = {}

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

return M
```

### Phase 4: Code Completion Integration

#### File: `lua/nvim-aptos/completion.lua`

```lua
local M = {}

-- Setup completion for Move
M.setup_completion = function()
    local cmp = require('cmp')
    
    cmp.setup({
        snippet = {
            expand = function(args)
                require('luasnip').lsp_expand(args.body)
            end,
        },
        mapping = {
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.close(),
            ['<CR>'] = cmp.mapping.confirm({
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
            }),
        },
        sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'buffer' },
        },
    })
end

-- Move-specific completion items
M.move_completion_items = {
    -- Keywords
    keywords = {
        { label = "module", kind = "keyword", insertText = "module ${1:name} {\n\t$0\n}" },
        { label = "resource", kind = "keyword", insertText = "resource ${1:name} {\n\t$0\n}" },
        { label = "struct", kind = "keyword", insertText = "struct ${1:name} {\n\t$0\n}" },
        { label = "fun", kind = "keyword", insertText = "fun ${1:name}(${2:params}) {\n\t$0\n}" },
        { label = "public", kind = "keyword", insertText = "public " },
        { label = "entry", kind = "keyword", insertText = "entry " },
    },
    
    -- Types
    types = {
        { label = "u8", kind = "type" },
        { label = "u64", kind = "type" },
        { label = "u128", kind = "type" },
        { label = "u256", kind = "type" },
        { label = "bool", kind = "type" },
        { label = "address", kind = "type" },
        { label = "vector", kind = "type" },
    },
    
    -- Built-in functions
    builtins = {
        { label = "assert!", kind = "function", insertText = "assert!(${1:condition}, ${2:error_code})" },
        { label = "error!", kind = "function", insertText = "error!(${1:error_code})" },
        { label = "abort!", kind = "function", insertText = "abort!(${1:error_code})" },
        { label = "exists!", kind = "function", insertText = "exists!<${1:type}>(${2:address})" },
    }
}

return M
```

## Configuration Options

### User Configuration

```lua
require('nvim-aptos').setup({
    lsp = {
        enable = true,
        server = "move_analyzer", -- "move_analyzer" or "move-analyzer"
        settings = {
            diagnostics = {
                enable = true,
                experimental = true,
            },
            hover = {
                enable = true,
            },
            completion = {
                enable = true,
            },
        },
        keymaps = {
            -- Custom keymaps
            goto_definition = "gd",
            references = "gr",
            hover = "K",
            rename = "<leader>rn",
            code_action = "<leader>ca",
        }
    }
})
```

## Testing Strategy

### LSP Feature Tests

1. **Definition Jumping**
   - Test jumping to function definitions
   - Test jumping to struct/resource definitions
   - Test jumping to module definitions
   - Test cross-file navigation

2. **Reference Finding**
   - Test finding all usages of a symbol
   - Test reference counting
   - Test workspace-wide references

3. **Code Completion**
   - Test keyword completion
   - Test type completion
   - Test function completion
   - Test snippet expansion

4. **Hover Information**
   - Test type information display
   - Test documentation display
   - Test error information

### Integration Testing

1. **Multi-file Projects**
   - Test navigation across multiple Move files
   - Test workspace symbol search
   - Test cross-module references

2. **Error Handling**
   - Test LSP server failures
   - Test network connectivity issues
   - Test malformed responses

## Performance Considerations

1. **Large Workspaces**
   - Optimize symbol indexing
   - Implement lazy loading for large projects
   - Cache frequently accessed symbols

2. **Memory Usage**
   - Monitor LSP client memory usage
   - Implement cleanup for unused symbols
   - Optimize completion item storage

## Future Enhancements

1. **Advanced Refactoring**
   - Extract function
   - Rename across workspace
   - Move to file

2. **Debugging Integration**
   - Breakpoint management
   - Variable inspection
   - Call stack navigation

3. **Testing Integration**
   - Test discovery
   - Test execution
   - Test result display 