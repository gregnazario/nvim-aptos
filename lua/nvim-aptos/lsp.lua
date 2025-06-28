local M = {}

local lspconfig = require('lspconfig')
local api = vim.api

-- LSP configuration for Move
M.setup_lsp = function(config)
    local default_config = {
        capabilities = M.get_capabilities(),
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
    
    -- Setup custom LSP server if needed
    M.setup_custom_server()
    
    -- Setup LSP for Move files
    lspconfig.move_analyzer.setup(config)
end

-- Get LSP capabilities
M.get_capabilities = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    
    -- Try to get capabilities from cmp if available
    local status_ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
    if status_ok then
        capabilities = cmp_lsp.default_capabilities()
    end
    
    return capabilities
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
    
    -- Show diagnostic on hover
    vim.api.nvim_create_autocmd("CursorHold", {
        buffer = bufnr,
        callback = function()
            local opts = {
                focusable = false,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                border = 'rounded',
                source = 'always',
                prefix = ' ',
                scope = 'cursor',
            }
            vim.diagnostic.open_float(nil, opts)
        end
    })
end

-- Setup custom LSP server
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

-- Get LSP client for current buffer
M.get_client = function()
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
        if client.name == "move_analyzer" then
            return client
        end
    end
    return nil
end

-- Check if LSP is attached to current buffer
M.is_attached = function()
    return M.get_client() ~= nil
end

-- Restart LSP
M.restart = function()
    local client = M.get_client()
    if client then
        client.stop()
        vim.defer_fn(function()
            M.setup_lsp()
        end, 100)
    end
end

-- Get LSP status
M.get_status = function()
    local client = M.get_client()
    if client then
        return "move_analyzer: " .. client.state
    else
        return "move_analyzer: not attached"
    end
end

return M 