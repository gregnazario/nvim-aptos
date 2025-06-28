# Aptos CLI Integration Plan

## Overview

This document outlines the implementation of comprehensive Aptos CLI integration for Neovim, enabling developers to execute build, test, deployment, and account management commands directly within the editor.

## CLI Features

### Core CLI Features
1. **Build Commands** - Compile Move modules and scripts
2. **Test Execution** - Run Move tests with detailed output
3. **Account Management** - Create and manage Aptos accounts
4. **Transaction Submission** - Submit transactions to the network
5. **Network Operations** - Interact with different Aptos networks

### Advanced Features
1. **Project Management** - Initialize and manage Move projects
2. **Package Management** - Handle dependencies and packages
3. **Deployment Automation** - Automated module deployment
4. **Network Switching** - Easy switching between networks
5. **Transaction Monitoring** - Track transaction status

## Implementation Strategy

### Phase 1: Basic CLI Integration

#### File: `lua/nvim-aptos/cli.lua`

```lua
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
end

return M
```

### Phase 2: Build and Test Commands

#### File: `lua/nvim-aptos/cli/build.lua`

```lua
local M = {}

-- Build Move project
M.build_project = function()
    local project_root = M.find_project_root()
    if not project_root then
        vim.notify("No Move.toml found in current directory or parents", vim.log.levels.ERROR)
        return
    end
    
    vim.notify("Building Move project...", vim.log.levels.INFO)
    
    local cmd = { "aptos", "move", "build", "--package-dir", project_root }
    
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
    
    local cmd = { "aptos", "move", "test", "--package-dir", project_root }
    
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

-- Parse build output
M.parse_build_output = function(output)
    local lines = {}
    for _, line in ipairs(output) do
        if line:match("Compiling") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("Built") then
            table.insert(lines, "✓ " .. line)
        end
    end
    
    if #lines > 0 then
        M.show_output_window("Build Output", lines)
    end
end

-- Parse build errors
M.parse_build_errors = function(errors)
    local lines = {}
    for _, line in ipairs(errors) do
        if line:match("error:") then
            table.insert(lines, "✗ " .. line)
        elseif line:match("warning:") then
            table.insert(lines, "⚠ " .. line)
        end
    end
    
    if #lines > 0 then
        M.show_output_window("Build Errors", lines)
    end
end

-- Parse test output
M.parse_test_output = function(output)
    local lines = {}
    local test_count = 0
    local passed_count = 0
    
    for _, line in ipairs(output) do
        if line:match("Running") then
            test_count = test_count + 1
            table.insert(lines, "▶ " .. line)
        elseif line:match("PASS") then
            passed_count = passed_count + 1
            table.insert(lines, "✓ " .. line)
        elseif line:match("FAIL") then
            table.insert(lines, "✗ " .. line)
        end
    end
    
    table.insert(lines, 1, string.format("Test Results: %d/%d passed", passed_count, test_count))
    M.show_output_window("Test Results", lines)
end

-- Parse test errors
M.parse_test_errors = function(errors)
    local lines = {}
    for _, line in ipairs(errors) do
        if line:match("FAIL") then
            table.insert(lines, "✗ " .. line)
        elseif line:match("error:") then
            table.insert(lines, "✗ " .. line)
        end
    end
    
    if #lines > 0 then
        M.show_output_window("Test Errors", lines)
    end
end

-- Show output in a new window
M.show_output_window = function(title, lines)
    local buf = api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    }
    
    local win = api.nvim_open_win(buf, true, opts)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_buf_set_option(buf, "modifiable", false)
    api.nvim_buf_set_option(buf, "filetype", "aptos_output")
    
    -- Add close keymap
    api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, "n", "<ESC>", "<cmd>close<CR>", { noremap = true, silent = true })
    
    -- Set window title
    api.nvim_win_set_option(win, "title", true)
    api.nvim_win_set_option(win, "titlepos", "center")
    api.nvim_win_set_option(win, "titlestring", title)
end

return M
```

### Phase 3: Account and Network Management

#### File: `lua/nvim-aptos/cli/account.lua`

```lua
local M = {}

-- Show account information
M.show_account_info = function()
    local cmd = { "aptos", "account", "list", "--output", "json" }
    
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
    local cmd = { "aptos", "init", "--profile", "default" }
    
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
    
    local cmd = { "aptos", "init", "--profile", "default", "--network", network }
    
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
    local cmd = { "aptos", "node", "show-validator-set", "--output", "json" }
    
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

-- Parse account information
M.parse_account_info = function(output)
    local success, data = pcall(vim.json.decode, table.concat(output, "\n"))
    if not success then
        vim.notify("Failed to parse account info", vim.log.levels.ERROR)
        return
    end
    
    local lines = { "Account Information:" }
    
    if data.result and data.result[1] then
        local account = data.result[1]
        table.insert(lines, "Address: " .. account.address)
        table.insert(lines, "Sequence Number: " .. account.sequence_number)
        table.insert(lines, "Authentication Key: " .. account.authentication_key)
    end
    
    M.show_output_window("Account Info", lines)
end

-- Parse account creation
M.parse_account_creation = function(output)
    local lines = { "Account Creation:" }
    
    for _, line in ipairs(output) do
        if line:match("Aptos") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("address") then
            table.insert(lines, "📍 " .. line)
        elseif line:match("private") then
            table.insert(lines, "🔑 " .. line)
        end
    end
    
    M.show_output_window("Account Created", lines)
end

-- Parse network switch
M.parse_network_switch = function(output)
    local lines = { "Network Switch:" }
    
    for _, line in ipairs(output) do
        if line:match("Aptos") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("network") then
            table.insert(lines, "🌐 " .. line)
        end
    end
    
    M.show_output_window("Network Switched", lines)
end

-- Parse network information
M.parse_network_info = function(output)
    local success, data = pcall(vim.json.decode, table.concat(output, "\n"))
    if not success then
        vim.notify("Failed to parse network info", vim.log.levels.ERROR)
        return
    end
    
    local lines = { "Network Information:" }
    
    if data.result then
        table.insert(lines, "Total Validators: " .. data.result.total_voting_power)
        table.insert(lines, "Active Validators: " .. #data.result.active_validators)
    end
    
    M.show_output_window("Network Info", lines)
end

return M
```

### Phase 4: Deployment and Transaction Management

#### File: `lua/nvim-aptos/cli/deploy.lua`

```lua
local M = {}

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
    
    local cmd = { "aptos", "move", "publish", "--package-dir", project_root }
    
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

-- Submit transaction
M.submit_transaction = function(script_path, args)
    if not script_path then
        vim.notify("Script path is required", vim.log.levels.ERROR)
        return
    end
    
    local cmd = { "aptos", "move", "run", "--script-path", script_path }
    
    if args then
        for _, arg in ipairs(args) do
            table.insert(cmd, "--args")
            table.insert(cmd, arg)
        end
    end
    
    vim.notify("Submitting transaction...", vim.log.levels.INFO)
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                vim.notify("Transaction submitted successfully!", vim.log.levels.INFO)
                M.parse_transaction_output(stdout)
            else
                vim.notify("Transaction failed!", vim.log.levels.ERROR)
                M.parse_transaction_errors(stderr)
            end
        end,
    })
end

-- Monitor transaction
M.monitor_transaction = function(txn_hash)
    if not txn_hash then
        vim.notify("Transaction hash is required", vim.log.levels.ERROR)
        return
    end
    
    local cmd = { "aptos", "transaction", "show", "--hash", txn_hash, "--output", "json" }
    
    job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_exit = function(_, exit_code, stdout, stderr)
            if exit_code == 0 then
                M.parse_transaction_status(stdout)
            else
                vim.notify("Failed to get transaction status: " .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
            end
        end,
    })
end

-- Get current network
M.get_current_network = function()
    local cmd = { "aptos", "config", "show-global-config", "--output", "json" }
    
    local handle = io.popen(table.concat(cmd, " "))
    local result = handle:read("*a")
    handle:close()
    
    local success, data = pcall(vim.json.decode, result)
    if success and data.config then
        return data.config.network or "unknown"
    end
    
    return "unknown"
end

-- Parse deployment output
M.parse_deployment_output = function(output)
    local lines = { "Deployment Results:" }
    
    for _, line in ipairs(output) do
        if line:match("Transaction") then
            table.insert(lines, "📝 " .. line)
        elseif line:match("Success") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("hash") then
            table.insert(lines, "🔗 " .. line)
        end
    end
    
    M.show_output_window("Deployment", lines)
end

-- Parse deployment errors
M.parse_deployment_errors = function(errors)
    local lines = { "Deployment Errors:" }
    
    for _, line in ipairs(errors) do
        if line:match("error:") then
            table.insert(lines, "✗ " .. line)
        elseif line:match("warning:") then
            table.insert(lines, "⚠ " .. line)
        end
    end
    
    M.show_output_window("Deployment Errors", lines)
end

-- Parse transaction output
M.parse_transaction_output = function(output)
    local lines = { "Transaction Results:" }
    
    for _, line in ipairs(output) do
        if line:match("Transaction") then
            table.insert(lines, "📝 " .. line)
        elseif line:match("Success") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("hash") then
            table.insert(lines, "🔗 " .. line)
        end
    end
    
    M.show_output_window("Transaction", lines)
end

-- Parse transaction errors
M.parse_transaction_errors = function(errors)
    local lines = { "Transaction Errors:" }
    
    for _, line in ipairs(errors) do
        if line:match("error:") then
            table.insert(lines, "✗ " .. line)
        elseif line:match("warning:") then
            table.insert(lines, "⚠ " .. line)
        end
    end
    
    M.show_output_window("Transaction Errors", lines)
end

-- Parse transaction status
M.parse_transaction_status = function(output)
    local success, data = pcall(vim.json.decode, table.concat(output, "\n"))
    if not success then
        vim.notify("Failed to parse transaction status", vim.log.levels.ERROR)
        return
    end
    
    local lines = { "Transaction Status:" }
    
    if data.result then
        local txn = data.result
        table.insert(lines, "Hash: " .. txn.hash)
        table.insert(lines, "Status: " .. txn.success)
        table.insert(lines, "Version: " .. txn.version)
        table.insert(lines, "Gas Used: " .. txn.gas_used)
    end
    
    M.show_output_window("Transaction Status", lines)
end

return M
```

### Phase 5: Project Management

#### File: `lua/nvim-aptos/cli/project.lua`

```lua
local M = {}

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
    local cmd = { "aptos", "move", "init", "--name", project_name }
    
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
    
    local cmd = { "aptos", "move", "add", "--package-dir", project_root, dependency }
    
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

-- Parse project initialization
M.parse_project_init = function(output)
    local lines = { "Project Initialization:" }
    
    for _, line in ipairs(output) do
        if line:match("Created") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("Move.toml") then
            table.insert(lines, "📄 " .. line)
        end
    end
    
    M.show_output_window("Project Initialized", lines)
end

-- Parse dependency addition
M.parse_dependency_add = function(output)
    local lines = { "Dependency Added:" }
    
    for _, line in ipairs(output) do
        if line:match("Added") then
            table.insert(lines, "✓ " .. line)
        elseif line:match("dependency") then
            table.insert(lines, "📦 " .. line)
        end
    end
    
    M.show_output_window("Dependency Added", lines)
end

-- Parse project information
M.parse_project_info = function(content, project_root)
    local lines = { "Project Information:" }
    table.insert(lines, "Root: " .. project_root)
    
    -- Parse Move.toml content
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%s*name%s*=") then
            local name = line:match("name%s*=%s*\"([^\"]+)\"")
            if name then
                table.insert(lines, "Name: " .. name)
            end
        elseif line:match("^%s*version%s*=") then
            local version = line:match("version%s*=%s*\"([^\"]+)\"")
            if version then
                table.insert(lines, "Version: " .. version)
            end
        elseif line:match("^%s*%[dependencies%]") then
            table.insert(lines, "Dependencies:")
        elseif line:match("^%s*%w+%s*=") and not line:match("^%s*%[") then
            local dep = line:match("^%s*([^%s=]+)")
            if dep and dep ~= "name" and dep ~= "version" then
                table.insert(lines, "  - " .. dep)
            end
        end
    end
    
    M.show_output_window("Project Info", lines)
end

return M
```

## Configuration Options

### User Configuration

```lua
require('nvim-aptos').setup({
    cli = {
        enable = true,
        aptos_path = "aptos",
        default_network = "devnet",
        output_format = "json",
        timeout = 30000,
        commands = {
            build = {
                enable = true,
                auto_save = true,
            },
            test = {
                enable = true,
                coverage = false,
            },
            deploy = {
                enable = true,
                confirm = true,
            },
            account = {
                enable = true,
                auto_create = false,
            },
        },
        keymaps = {
            build = "<leader>ab",
            test = "<leader>at",
            deploy = "<leader>ad",
            account = "<leader>aa",
            network = "<leader>as",
        }
    }
})
```

## Testing Strategy

### CLI Feature Tests

1. **Build Commands**
   - Test project building
   - Test build error handling
   - Test build output parsing

2. **Test Commands**
   - Test test execution
   - Test test result parsing
   - Test test failure handling

3. **Account Management**
   - Test account creation
   - Test account information display
   - Test network switching

4. **Deployment**
   - Test module deployment
   - Test transaction submission
   - Test deployment confirmation

### Integration Testing

1. **CLI Availability**
   - Test aptos CLI detection
   - Test CLI version compatibility
   - Test CLI command availability

2. **Project Management**
   - Test project initialization
   - Test dependency management
   - Test project information display

3. **Error Handling**
   - Test network connectivity issues
   - Test authentication failures
   - Test invalid command handling

## Future Enhancements

1. **Advanced Deployment**
   - Multi-network deployment
   - Deployment rollback
   - Deployment verification

2. **Transaction Management**
   - Transaction batching
   - Transaction scheduling
   - Transaction monitoring dashboard

3. **Project Templates**
   - Custom project templates
   - Template management
   - Template sharing

4. **Package Management**
   - Package search
   - Package version management
   - Package compatibility checking 