local M = {}

-- Default configuration
local default_config = {
    syntax = {
        enable_treesitter = true,
        enable_traditional = false,
        custom_highlights = {},
        fold_method = "treesitter",
    },
    lsp = {
        enable = true,
        server = "move_analyzer",
        settings = {
            diagnostics = { enable = true, experimental = true },
            hover = { enable = true },
            completion = { enable = true },
        },
        keymaps = {
            goto_definition = "gd",
            references = "gr",
            hover = "K",
            rename = "<leader>rn",
            code_action = "<leader>ca",
        }
    },
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
    },
    cli = {
        enable = true,
        aptos_path = "aptos",
        default_network = "devnet",
        output_format = "json",
        timeout = 30000,
        commands = {
            build = { enable = true, auto_save = true },
            test = { enable = true, coverage = false },
            deploy = { enable = true, confirm = true },
            account = { enable = true, auto_create = false },
        },
        keymaps = {
            build = "<leader>ab",
            test = "<leader>at",
            deploy = "<leader>ad",
            account = "<leader>aa",
            network = "<leader>as",
        }
    }
}

-- Plugin state
M.config = {}
M.initialized = false

-- Setup function
M.setup = function(config)
    if M.initialized then
        return
    end
    
    -- Merge user config with defaults
    M.config = vim.tbl_deep_extend("force", default_config, config or {})
    
    -- Initialize components
    M.init_syntax()
    M.init_lsp()
    M.init_diagnostics()
    M.init_cli()
    
    M.initialized = true
    vim.notify("nvim-aptos initialized successfully!", vim.log.levels.INFO)
end

-- Initialize syntax highlighting
M.init_syntax = function()
    if not M.config.syntax.enable_treesitter and not M.config.syntax.enable_traditional then
        return
    end
    
    local syntax = require('nvim-aptos.syntax')
    
    if M.config.syntax.enable_treesitter then
        syntax.setup_treesitter()
    end
    
    if M.config.syntax.enable_traditional then
        syntax.setup_traditional()
    end
    
    syntax.setup_highlights()
    syntax.setup_folding()
end

-- Initialize LSP
M.init_lsp = function()
    if not M.config.lsp.enable then
        return
    end
    
    local lsp = require('nvim-aptos.lsp')
    lsp.setup_lsp(M.config.lsp)
end

-- Initialize diagnostics
M.init_diagnostics = function()
    if not M.config.diagnostics.enable then
        return
    end
    
    local diagnostics = require('nvim-aptos.diagnostics')
    diagnostics.setup_diagnostics(M.config.diagnostics)
    
    if M.config.diagnostics.realtime then
        local realtime = require('nvim-aptos.diagnostics.realtime')
        realtime.setup_realtime_checking()
    end
    
    local display = require('nvim-aptos.diagnostics.display')
    display.setup_custom_display()
    
    local navigation = require('nvim-aptos.diagnostics.navigation')
    navigation.setup_navigation()
end

-- Initialize CLI
M.init_cli = function()
    if not M.config.cli.enable then
        return
    end
    
    local cli = require('nvim-aptos.cli')
    cli.setup(M.config.cli)
end

-- Public API functions
M.goto_definition = function()
    if M.config.lsp.enable then
        local navigation = require('nvim-aptos.navigation')
        navigation.goto_definition()
    end
end

M.format = function()
    if M.config.lsp.enable then
        vim.lsp.buf.format()
    end
end

M.run_tests = function()
    if M.config.cli.enable then
        local build = require('nvim-aptos.cli.build')
        build.run_tests()
    end
end

M.build_project = function()
    if M.config.cli.enable then
        local build = require('nvim-aptos.cli.build')
        build.build_project()
    end
end

M.deploy_modules = function()
    if M.config.cli.enable then
        local deploy = require('nvim-aptos.cli.deploy')
        deploy.deploy_modules()
    end
end

M.show_account_info = function()
    if M.config.cli.enable then
        local account = require('nvim-aptos.cli.account')
        account.show_account_info()
    end
end

M.switch_network = function(network)
    if M.config.cli.enable then
        local account = require('nvim-aptos.cli.account')
        account.switch_network(network)
    end
end

return M 