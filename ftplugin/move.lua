-- Move-specific filetype settings
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true
vim.opt_local.commentstring = "// %s"

-- Custom keymaps for Move development
local opts = { buffer = true, silent = true }

-- Jump to module definition
vim.keymap.set('n', 'gd', '<cmd>lua require("nvim-aptos").goto_definition()<CR>', opts)

-- Format Move code
vim.keymap.set('n', '<leader>f', '<cmd>lua require("nvim-aptos").format()<CR>', opts)

-- Run Move tests
vim.keymap.set('n', '<leader>t', '<cmd>lua require("nvim-aptos").run_tests()<CR>', opts)

-- Build project
vim.keymap.set('n', '<leader>b', '<cmd>lua require("nvim-aptos").build_project()<CR>', opts)

-- Deploy modules
vim.keymap.set('n', '<leader>d', '<cmd>lua require("nvim-aptos").deploy_modules()<CR>', opts)

-- Show account info
vim.keymap.set('n', '<leader>a', '<cmd>lua require("nvim-aptos").show_account_info()<CR>', opts)

-- Switch network
vim.keymap.set('n', '<leader>s', function()
    vim.ui.input({
        prompt = "Network (local/devnet/testnet/mainnet): ",
    }, function(input)
        if input and input ~= "" then
            require("nvim-aptos").switch_network(input)
        end
    end)
end, opts) 