# nvim-aptos

Neovim plugin for Aptos Move development. Tree-sitter highlighting, LSP integration, CLI commands, Move Prover, resource explorer, and gas estimation.

## Requirements

- **Neovim >= 0.10** (0.11+ for native LSP without lspconfig)
- [aptos CLI](https://aptos.dev/tools/aptos-cli/) on PATH
- [move-analyzer](https://github.com/aptos-labs/aptos-core) on PATH (for LSP)
- Tree-sitter parser: `move_on_aptos`

## Installation

### lazy.nvim

```lua
{
  "gregnazario/nvim-aptos",
  ft = "move",
  opts = {},
}
```

### packer.nvim

```lua
use {
  "gregnazario/nvim-aptos",
  config = function()
    require("nvim-aptos").setup()
  end,
}
```

### vim-plug

```vim
Plug 'gregnazario/nvim-aptos'

" In your init.lua or after/plugin:
lua require("nvim-aptos").setup()
```

### Manual

Clone to your Neovim packages directory:

```sh
git clone https://github.com/gregnazario/nvim-aptos \
  ~/.local/share/nvim/site/pack/plugins/start/nvim-aptos
```

Then add to your `init.lua`:

```lua
require("nvim-aptos").setup()
```

### Installing prerequisites

**aptos CLI:**

```sh
# macOS / Linux
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3

# Or via Homebrew
brew install aptos
```

**move-analyzer (LSP server):**

```sh
# Install from aptos-core (requires Rust toolchain)
cargo install --git https://github.com/aptos-labs/aptos-core move-analyzer
```

**Tree-sitter parser:**

If you use [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter):

```vim
:TSInstall move_on_aptos
```

To build manually (requires Node.js and a C compiler):

```sh
git clone https://github.com/aptos-labs/tree-sitter-move-on-aptos
cd tree-sitter-move-on-aptos
# Compile the parser
cc -o parser.so -shared src/parser.c src/scanner.c -I src -fPIC
# Copy to Neovim's parser directory
mkdir -p ~/.local/share/nvim/site/parser
cp parser.so ~/.local/share/nvim/site/parser/move_on_aptos.so
```

After installing, verify with `:checkhealth nvim-aptos`.

## Configuration

All defaults shown — only override what you need:

```lua
require("nvim-aptos").setup({
  syntax = {
    enable = true,       -- tree-sitter highlighting
    folds = true,        -- tree-sitter folding
  },
  lsp = {
    enable = true,
    cmd = { "move-analyzer" },
    keymaps = {
      definition = "gd",       -- set to false to disable
      references = "gr",
      hover = "K",
      rename = "<leader>rn",
      code_action = "<leader>ca",
    },
  },
  cli = {
    enable = true,
    aptos_path = "aptos",      -- path to aptos binary
    keymaps = {
      build = "<leader>ab",
      test = "<leader>at",
      publish = "<leader>ap",
    },
  },
  prover = {
    enable = true,
    keymap = "<leader>av",
  },
  explorer = {
    enable = true,
    keymap = "<leader>ae",
  },
  gas = {
    enable = true,
    keymap = "<leader>ag",
  },
})
```

## Commands

All commands are buffer-local to `.move` files.

| Command | Description |
|---------|-------------|
| `:AptosBuild` | Compile Move package |
| `:AptosTest [filter]` | Run unit tests (optional filter) |
| `:AptosPublish` | Publish modules (with confirmation) |
| `:AptosInit [name]` | Initialize a new Move project |
| `:AptosAccount` | Show account info |
| `:AptosNetwork [net]` | Switch network (devnet/testnet/mainnet/local) |
| `:AptosProve [func]` | Run Move Prover |
| `:AptosExplore [addr]` | Browse on-chain resources |
| `:AptosGas` | Estimate gas for publish |

## Keymaps

All keymaps are buffer-local to `.move` files and configurable (set to `false` to disable).

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |

### CLI

| Key | Action |
|-----|--------|
| `<leader>ab` | Build |
| `<leader>at` | Test |
| `<leader>ap` | Publish |
| `<leader>av` | Prove |
| `<leader>ae` | Explore resources |
| `<leader>ag` | Gas estimation |

## Health Check

```vim
:checkhealth nvim-aptos
```

Checks for: Neovim version, move-analyzer, aptos CLI, tree-sitter parser, LSP config availability.

## Running Tests

```sh
make test
```

Or run individual test files:

```sh
nvim --headless -u tests/minimal_init.lua -c "luafile tests/test_util.lua" -c "qa!"
nvim --headless -u tests/minimal_init.lua -c "luafile tests/test_init.lua" -c "qa!"
nvim --headless -u tests/minimal_init.lua -c "luafile tests/test_cli.lua" -c "qa!"
```

## License

MIT
