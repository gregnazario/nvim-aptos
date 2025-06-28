# nvim-aptos

A comprehensive Neovim plugin for Aptos Move language development, providing syntax highlighting, LSP integration, error diagnostics, and CLI integration.

## Features

- **Syntax Highlighting** - Full support for Move language syntax with custom highlighting
- **Jump to Definition** - Navigate to function, struct, resource, and module definitions
- **Error Highlighting** - Real-time error detection and diagnostic display
- **Aptos CLI Integration** - Build, test, deploy, and manage accounts directly from Neovim

## Installation

### Using packer.nvim
```lua
use {
    'your-username/nvim-aptos',
    requires = {
        'nvim-lspconfig',
        'nvim-treesitter',
        'plenary.nvim',
    }
}
```

### Using lazy.nvim
```lua
{
    'your-username/nvim-aptos',
    dependencies = {
        'nvim-lspconfig',
        'nvim-treesitter',
        'plenary.nvim',
    },
    config = function()
        require('nvim-aptos').setup()
    end
}
```

## Setup

```lua
require('nvim-aptos').setup({
    -- Syntax highlighting configuration
    syntax = {
        enable_treesitter = true,
        enable_traditional = false,
        custom_highlights = {},
        fold_method = "treesitter",
    },
    
    -- LSP configuration
    lsp = {
        enable = true,
        server = "move_analyzer",
        settings = {
            diagnostics = { enable = true, experimental = true },
            hover = { enable = true },
            completion = { enable = true },
        },
    },
    
    -- Diagnostics configuration
    diagnostics = {
        enable = true,
        realtime = true,
        debounce_time = 500,
        display = {
            virtual_text = true,
            signs = true,
            underline = true,
        },
    },
    
    -- CLI configuration
    cli = {
        enable = true,
        aptos_path = "aptos",
        default_network = "devnet",
        timeout = 30000,
    }
})
```

## Keymaps

### LSP Navigation
- `gd` - Go to definition
- `gr` - Go to references
- `K` - Hover information
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions

### Diagnostics
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>e` - Show diagnostic float
- `<leader>f` - Quick fix

### CLI Commands
- `<leader>ab` - Build project
- `<leader>at` - Run tests
- `<leader>ad` - Deploy modules
- `<leader>aa` - Show account info
- `<leader>as` - Switch network

## Commands

- `:AptosBuild` - Build Move project
- `:AptosTest` - Run Move tests
- `:AptosDeploy` - Deploy Move modules
- `:AptosAccount` - Show account information
- `:AptosNetwork <network>` - Switch Aptos network

## Requirements

- Neovim 0.8.0+
- Aptos CLI installed and in PATH
- Move Analyzer LSP server (optional)

## Documentation

See the [docs](./docs/) directory for detailed implementation plans:

- [PLAN.md](./docs/PLAN.md) - Overall implementation plan
- [SYNTAX.md](./docs/SYNTAX.md) - Syntax highlighting implementation
- [LSP.md](./docs/LSP.md) - Language Server Protocol integration
- [DIAGNOSTICS.md](./docs/DIAGNOSTICS.md) - Error highlighting and diagnostics
- [CLI.md](./docs/CLI.md) - Aptos CLI integration

## Contributing

Contributions are welcome! Please read the documentation and follow the existing code style.

## License

MIT License - see [LICENSE](./LICENSE) for details.