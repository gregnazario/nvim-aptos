local M = {}

local api = vim.api
local job = vim.fn.jobstart

-- CLI configuration
M.config = {
    aptos_path = "aptos",
    default_network = "devnet",
    output_format = "json",
    timeout = 30000, -- 30 seconds
}

-- Setup CLI integration
M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})
    
    -- Verify aptos CLI is available
    M.verify_aptos_cli()
    
    -- Setup CLI commands
    M.setup_commands()
    
    -- Setup keymaps
    M.setup_keymaps()
end

-- Verify aptos CLI is available
M.verify_aptos_cli = function()
    local handle = io.popen("which " .. M.config.aptos_path)
    local result = handle:read("*a")
    handle:close()
    
    if result == "" then
        vim.notify("Aptos CLI not found. Please install aptos CLI.", vim.log.levels.ERROR)
        return false
    end
    
    return true
end

-- Setup CLI commands
M.setup_commands = function()
    -- Build command
    vim.api.nvim_create_user_command("AptosBuild", function()
        M.build_project()
    end, { desc = "Build Move project" })
    
    -- Test command
    vim.api.nvim_create_user_command("AptosTest", function()
        M.run_tests()
    end, { desc = "Run Move tests" })
    
    -- Deploy command
    vim.api.nvim_create_user_command("AptosDeploy", function()
        M.deploy_modules()
    end, { desc = "Deploy Move modules" })
    
    -- Account info command
    vim.api.nvim_create_user_command("AptosAccount", function()
        M.show_account_info()
    end, { desc = "Show account information" })
    
    -- Network switch command
    vim.api.nvim_create_user_command("AptosNetwork", function(opts)
        M.switch_network(opts.args)
    end, { desc = "Switch Aptos network", nargs = 1 })
    
    -- Init project command
    vim.api.nvim_create_user_command("AptosInit", function(opts)
        M.init_project(opts.args)
    end, { desc = "Initialize Move project", nargs = "?" })
    
    -- Add dependency command
    vim.api.nvim_create_user_command("AptosAdd", function(opts)
        M.add_dependency(opts.args)
    end, { desc = "Add dependency", nargs = "?" })
end

-- Setup keymaps
M.setup_keymaps = function()
    local opts = { noremap = true, silent = true }
    
    -- Build and test
    vim.keymap.set('n', '<leader>ab', M.build_project, opts)
    vim.keymap.set('n', '<leader>at', M.run_tests, opts)
    vim.keymap.set('n', '<leader>ad', M.deploy_modules, opts)
    
    -- Account management
    vim.keymap.set('n', '<leader>aa', M.show_account_info, opts)
    vim.keymap.set('n', '<leader>an', M.create_account, opts)
    
    -- Network operations
    vim.keymap.set('n', '<leader>as', M.switch_network, opts)
    vim.keymap.set('n', '<leader>ai', M.show_network_info, opts)
    
    -- Project management
    vim.keymap.set('n', '<leader>ap', M.show_project_info, opts)
end

-- Find project root (directory containing Move.toml)
M.find_project_root = function()
    local current_dir = vim.fn.getcwd()
    local dir = current_dir
    
    while dir ~= "/" do
        local move_toml = dir .. "/Move.toml"
        local file = io.open(move_toml, "r")
        if file then
            file:close()
            return dir
        end
        dir = vim.fn.fnamemodify(dir, ":h")
    end
    
    return nil
end

-- Build Move project
M.build_project = function()
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    vim.notify("Building Move project...", vim.log.levels.INFO)
    
    local cmd = { M.config.aptos_path, "move", "build", "--package-dir", project_root }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Build successful!", vim.log.levels.INFO)
                M.parse_build_output(stdout)
            else
                vim.notify("Build failed!", vim.log.levels.ERROR)
                M.parse_build_errors(stderr)
            end
        end,
    })
end

-- Run Move tests
M.run_tests = function()
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    vim.notify("Running Move tests...", vim.log.levels.INFO)
    
    local cmd = { M.config.aptos_path, "move", "test", "--package-dir", project_root }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("All tests passed!", vim.log.levels.INFO)
                M.parse_test_output(stdout)
            else
                vim.notify("Some tests failed!", vim.log.levels.WARN)
                M.parse_test_errors(stderr)
            end
        end,
    })
end

-- Deploy Move modules
M.deploy_modules = function()
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    -- Confirm deployment
    vim.ui.select({ "Yes", "No" }, {
        prompt = "Deploy modules to " .. M.get_current_network() .. "?",
    }, function(choice)
        if choice == "Yes" then
            M.execute_deployment(project_root)
        end
    end)
end

-- Execute deployment
M.execute_deployment = function(project_root)
    vim.notify("Deploying modules...", vim.log.levels.INFO)
    
    local cmd = { M.config.aptos_path, "move", "publish", "--package-dir", project_root }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Deployment successful!", vim.log.levels.INFO)
                M.parse_deployment_output(stdout)
            else
                vim.notify("Deployment failed!", vim.log.levels.ERROR)
                M.parse_deployment_errors(stderr)
            end
        end,
    })
end

-- Show account information
M.show_account_info = function()
    local cmd = { M.config.aptos_path, "account", "list", "--output", "json" }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                M.parse_account_info(stdout)
            else
                vim.notify("Failed to get account info: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Create new account
M.create_account = function()
    local cmd = { M.config.aptos_path, "init", "--profile", "default" }
    
    vim.notify("Creating new account...", vim.log.levels.INFO)
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Account created successfully!", vim.log.levels.INFO)
                M.parse_account_creation(stdout)
            else
                vim.notify("Failed to create account: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Switch network
M.switch_network = function(network)
    if not network then
        vim.ui.input({
            prompt = "Network (local/devnet/testnet/mainnet): ",
        }, function(input)
            if input and input ~= "" then
                M.execute_network_switch(input)
            end
        end)
        return
    end
    
    M.execute_network_switch(network)
end

-- Execute network switch
M.execute_network_switch = function(network)
    local valid_networks = { "local", "devnet", "testnet", "mainnet" }
    local valid = false
    
    for _, net in ipairs(valid_networks) do
        if net == network then
            valid = true
            break
        end
    end
    
    if not valid then
        vim.notify("Invalid network. Valid options: " .. table.concat(valid_networks, ", "), vim.log.levels.ERROR)
        return
    end
    
    local cmd = { M.config.aptos_path, "init", "--profile", "default", "--network", network }
    
    vim.notify("Switching to " .. network .. "...", vim.log.levels.INFO)
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Switched to " .. network .. " successfully!", vim.log.levels.INFO)
                M.parse_network_switch(stdout)
            else
                vim.notify("Failed to switch network: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Show network information
M.show_network_info = function()
    local cmd = { M.config.aptos_path, "node", "show-validator-set", "--output", "json" }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                M.parse_network_info(stdout)
            else
                vim.notify("Failed to get network info: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Initialize new Move project
M.init_project = function(project_name)
    if not project_name then
        vim.ui.input({
            prompt = "Project name: ",
        }, function(input)
            if input and input ~= "" then
                M.execute_init_project(input)
            end
        end)
        return
    end
    
    M.execute_init_project(project_name)
end

-- Execute project initialization
M.execute_init_project = function(project_name)
    local cmd = { M.config.aptos_path, "move", "init", "--name", project_name }
    
    vim.notify("Initializing Move project: " .. project_name, vim.log.levels.INFO)
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Project initialized successfully!", vim.log.levels.INFO)
                M.parse_project_init(stdout)
            else
                vim.notify("Failed to initialize project: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Add dependency
M.add_dependency = function(dependency)
    if not dependency then
        vim.ui.input({
            prompt = "Dependency (format: address::module): ",
        }, function(input)
            if input and input ~= "" then
                M.execute_add_dependency(input)
            end
        end)
        return
    end
    
    M.execute_add_dependency(dependency)
end

-- Execute add dependency
M.execute_add_dependency = function(dependency)
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    local cmd = { M.config.aptos_path, "move", "add", "--package-dir", project_root, dependency }
    
    vim.notify("Adding dependency: " .. dependency, vim.log.levels.INFO)
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Dependency added successfully!", vim.log.levels.INFO)
                M.parse_dependency_add(stdout)
            else
                vim.notify("Failed to add dependency: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Show project information
M.show_project_info = function()
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    local move_toml_path = project_root .. "/Move.toml"
    local file = io.open(move_toml_path, "r")
    if not file then
        vim.notify("Cannot read Move.toml", vim.log.levels.ERROR)
        return
    end
    
    local content = file:read("*a")
    file:close()
    
    M.parse_project_info(content, project_root)
end

-- Get current network
M.get_current_network = function()
    local cmd = { M.config.aptos_path, "config", "show-global-config", "--output", "json" }
    
    local handle = io.popen(table.concat(cmd, " "))
    local result = handle:read("*a")
    handle:close()
    
    local success, data = pcall(vim.json.decode, result)
    if success and data.config then
        return data.config.network or "unknown"
    end
    
    return "unknown"
end

-- Parse functions (to be implemented in separate modules)
M.parse_build_output = function(output)
    -- Implementation will be in cli/build.lua
    vim.notify("Build completed successfully", vim.log.levels.INFO)
end

M.parse_build_errors = function(errors)
    -- Implementation will be in cli/build.lua
    vim.notify("Build failed: " .. table.concat(errors, "\n"), vim.log.levels.ERROR)
end

M.parse_test_output = function(output)
    -- Implementation will be in cli/build.lua
    vim.notify("Tests completed successfully", vim.log.levels.INFO)
end

M.parse_test_errors = function(errors)
    -- Implementation will be in cli/build.lua
    vim.notify("Tests failed: " .. table.concat(errors, "\n"), vim.log.levels.ERROR)
end

M.parse_deployment_output = function(output)
    -- Implementation will be in cli/deploy.lua
    vim.notify("Deployment completed successfully", vim.log.levels.INFO)
end

M.parse_deployment_errors = function(errors)
    -- Implementation will be in cli/deploy.lua
    vim.notify("Deployment failed: " .. table.concat(errors, "\n"), vim.log.levels.ERROR)
end

M.parse_account_info = function(output)
    -- Implementation will be in cli/account.lua
    vim.notify("Account info retrieved", vim.log.levels.INFO)
end

M.parse_account_creation = function(output)
    -- Implementation will be in cli/account.lua
    vim.notify("Account created successfully", vim.log.levels.INFO)
end

M.parse_network_switch = function(output)
    -- Implementation will be in cli/account.lua
    vim.notify("Network switched successfully", vim.log.levels.INFO)
end

M.parse_network_info = function(output)
    -- Implementation will be in cli/account.lua
    vim.notify("Network info retrieved", vim.log.levels.INFO)
end

M.parse_project_init = function(output)
    -- Implementation will be in cli/project.lua
    vim.notify("Project initialized successfully", vim.log.levels.INFO)
end

M.parse_dependency_add = function(output)
    -- Implementation will be in cli/project.lua
    vim.notify("Dependency added successfully", vim.log.levels.INFO)
end

M.parse_project_info = function(content, project_root)
    -- Implementation will be in cli/project.lua
    vim.notify("Project info retrieved", vim.log.levels.INFO)
end

return M 