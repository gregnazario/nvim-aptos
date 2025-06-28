" Vim syntax file for Move language
" Language: Move
" Maintainer: nvim-aptos
" Latest Revision: 2024

if exists("b:current_syntax")
  finish
endif

" Basic syntax groups
syntax keyword moveKeyword module use friend resource struct
syntax keyword moveKeyword fun public entry native inline
syntax keyword moveKeyword if else while loop return abort
syntax keyword moveKeyword script address signer
syntax keyword moveKeyword copy move ref mut
syntax keyword moveKeyword as where

" Type keywords
syntax keyword moveType u8 u64 u128 u256 bool address vector
syntax keyword moveType Option Some None

" Built-in functions
syntax keyword moveBuiltin assert! error! abort! exists! move_from
syntax keyword moveBuiltin borrow_global borrow_global_mut
syntax keyword moveBuiltin move_to_sender move_to
syntax keyword moveBuiltin freeze_to_extract thaw_from_extract
syntax keyword moveBuiltin split freeze thaw

" Literals
syntax match moveAddress /@[0-9a-fA-FxX]\+/
syntax region moveString start=/"/ end=/"/ skip=/\\"/
syntax match moveNumber /\<[0-9]\+\>/
syntax keyword moveBoolean true false

" Comments
syntax region moveComment start=/\/\// end=/$/
syntax region moveComment start=/\/\*/ end=/\*\//

" Module paths in use statements
syntax match moveModulePath /[A-Z][a-zA-Z0-9_]*::[a-zA-Z0-9_]*/ contained
syntax region moveUseStatement start=/use / end=/;/ contains=moveModulePath

" Function calls
syntax match moveFunctionCall /\<[a-zA-Z_][a-zA-Z0-9_]*\ze(/ contains=moveBuiltin

" Type parameters
syntax region moveTypeParam start=/</ end=/>/ contains=moveType

" Error codes
syntax match moveErrorCode /E[0-9]\+/

" Highlighting
highlight link moveKeyword Keyword
highlight link moveType Type
highlight link moveBuiltin Function
highlight link moveAddress Constant
highlight link moveString String
highlight link moveNumber Number
highlight link moveBoolean Boolean
highlight link moveComment Comment
highlight link moveModulePath Identifier
highlight link moveFunctionCall Function
highlight link moveTypeParam Type
highlight link moveErrorCode Error

let b:current_syntax = "move" 