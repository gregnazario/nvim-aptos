# Syntax Highlighting Implementation Plan

## Overview

This document details the implementation of syntax highlighting for the Aptos Move language in Neovim, covering both traditional Vim syntax files and modern Tree-sitter integration.

## Move Language Syntax Elements

### Keywords
- **Module System**: `module`, `use`, `friend`
- **Resource Management**: `resource`, `struct`, `copy`, `move`
- **Function Control**: `fun`, `public`, `entry`, `native`, `inline`
- **Type System**: `as`, `mut`, `ref`, `&`, `&mut`
- **Control Flow**: `if`, `else`, `while`, `loop`, `return`, `abort`
- **Error Handling**: `assert!`, `abort`, `error`
- **Generics**: `<`, `>`, `where`
- **Aptos Specific**: `script`, `address`, `signer`

### Literals
- **Numbers**: `u8`, `u64`, `u128`, `u256`
- **Booleans**: `true`, `false`
- **Addresses**: `@0x1`, `@std`, `@aptos_framework`
- **Strings**: `"string literals"`
- **Vectors**: `vector<T>`

### Operators
- **Arithmetic**: `+`, `-`, `*`, `/`, `%`
- **Comparison**: `==`, `!=`, `<`, `>`, `<=`, `>=`
- **Logical**: `&&`, `||`, `!`
- **Assignment**: `=`, `+=`, `-=`, `*=`, `/=`
- **Reference**: `&`, `&mut`, `*`

## Implementation Strategy

### Phase 1: Traditional Vim Syntax

#### File: `syntax/move.vim`

```vim
" Basic syntax groups
syntax keyword moveKeyword module use friend resource struct
syntax keyword moveKeyword fun public entry native inline
syntax keyword moveKeyword if else while loop return abort
syntax keyword moveKeyword script address signer

" Type keywords
syntax keyword moveType u8 u64 u128 u256 bool address vector
syntax keyword moveType copy move ref mut

" Built-in functions
syntax keyword moveBuiltin assert! error! abort! exists! move_from
syntax keyword moveBuiltin borrow_global borrow_global_mut

" Literals
syntax match moveAddress /@[0-9a-fA-FxX]\+/
syntax region moveString start=/"/ end=/"/ skip=/\\"/
syntax match moveNumber /\<[0-9]\+\>/
syntax keyword moveBoolean true false

" Comments
syntax region moveComment start=/\/\// end=/$/
syntax region moveComment start=/\/\*/ end=/\*\//

" Highlighting
highlight link moveKeyword Keyword
highlight link moveType Type
highlight link moveBuiltin Function
highlight link moveAddress Constant
highlight link moveString String
highlight link moveNumber Number
highlight link moveBoolean Boolean
highlight link moveComment Comment
```

#### File: `ftdetect/move.vim`

```vim
autocmd BufRead,BufNewFile *.move set filetype=move
autocmd BufRead,BufNewFile Move.toml set filetype=toml
```

### Phase 2: Tree-sitter Integration

#### File: `lua/nvim-aptos/syntax.lua`

```lua
local M = {}

-- Tree-sitter configuration for Move
M.setup_treesitter = function()
    local configs = require('nvim-treesitter.configs')
    
    configs.setup({
        ensure_installed = { "move" },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = true,
        },
    })
end

-- Custom highlight groups for Move
M.setup_highlights = function()
    local highlights = {
        -- Custom Move-specific highlights
        ["@move.keyword"] = { fg = "#C586C0" },
        ["@move.type"] = { fg = "#4EC9B0" },
        ["@move.function"] = { fg = "#DCDCAA" },
        ["@move.address"] = { fg = "#CE9178" },
        ["@move.resource"] = { fg = "#569CD6" },
        ["@move.module"] = { fg = "#4FC1FF" },
    }
    
    for group, settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, settings)
    end
end

-- Syntax-aware folding
M.setup_folding = function()
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
end

return M
```

### Phase 3: Advanced Features

#### Custom Syntax Rules

1. **Module Path Highlighting**
   - Highlight module paths in `use` statements
   - Different colors for standard library vs custom modules

2. **Resource/Struct Differentiation**
   - Distinct highlighting for resources vs structs
   - Special highlighting for resource operations

3. **Function Signature Highlighting**
   - Parameter types and names
   - Return type highlighting
   - Generic type parameters

4. **Error Context Highlighting**
   - Highlight error codes in `abort` statements
   - Custom error type highlighting

#### File: `ftplugin/move.lua`

```lua
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
```

## Configuration Options

### User Configuration

```lua
require('nvim-aptos').setup({
    syntax = {
        enable_treesitter = true,
        enable_traditional = false,
        custom_highlights = {
            -- User-defined highlight groups
        },
        fold_method = "treesitter", -- "treesitter" or "indent"
    }
})
```

## Testing Strategy

### Syntax Highlighting Tests

1. **Keyword Recognition**
   - Test all Move keywords are properly highlighted
   - Verify context-sensitive highlighting

2. **Literal Recognition**
   - Test address literals (`@0x1`, `@std`)
   - Test number literals with type annotations
   - Test string literals with escapes

3. **Comment Handling**
   - Test single-line comments
   - Test multi-line comments
   - Test comment nesting

4. **Complex Syntax**
   - Test module definitions
   - Test resource and struct definitions
   - Test function signatures with generics
   - Test use statements with aliases

### Performance Considerations

1. **Large File Handling**
   - Test syntax highlighting performance on large Move files
   - Optimize regex patterns for speed

2. **Memory Usage**
   - Monitor memory usage during syntax highlighting
   - Implement efficient highlight caching

## Integration with Other Features

### LSP Integration
- Coordinate syntax highlighting with LSP semantic tokens
- Handle LSP-based highlighting overrides

### Error Highlighting
- Integrate with diagnostic highlighting
- Show syntax errors in real-time

### Code Folding
- Implement syntax-aware folding for Move constructs
- Fold module definitions, functions, and blocks 