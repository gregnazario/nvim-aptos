; highlights.scm — tree-sitter highlight queries for Move on Aptos

; ─── Comments ────────────────────────────────────────────

(line_comment) @comment.line
(block_comment) @comment.block

; ─── Literals ────────────────────────────────────────────

(num_literal) @number
(bool_literal) @boolean
(byte_string_literal) @string
(hex_string_literal) @string
(address_literal) @string.special
(numerical_address) @number

; ─── Module & Script ─────────────────────────────────────

(module_declaration
  name: (_) @module)

(address_block
  "address" @keyword.module)

"module" @keyword.module
"script" @keyword.module

; ─── Imports ─────────────────────────────────────────────

"use" @keyword.import
"as" @keyword.import
"friend" @keyword.import

; ─── Functions ───────────────────────────────────────────

"fun" @keyword.function
"return" @keyword.return
"abort" @keyword.return

(function_declaration
  name: (identifier) @function)

(call_expression
  function: (name_access_chain
    name: (identifier) @function.call))

(call_expression
  function: (name_access_chain
    module: (identifier) @module
    name: (identifier) @function.call))

(macro_call_expression
  macro: (_) @function.macro)

; ─── Types & Structs ─────────────────────────────────────

"struct" @keyword.type
"enum" @keyword.type

(struct_declaration
  name: (identifier) @type.definition)

(enum_declaration
  name: (identifier) @type.definition)

(enum_variant
  name: (identifier) @type.enum.variant)

(primitive_type) @type.builtin

(ability) @type.qualifier

(field_declaration
  name: (identifier) @variable.member
  type: (_) @type)

; ─── Constants ───────────────────────────────────────────

"const" @keyword

(constant_declaration
  name: (identifier) @constant)

; ─── Control Flow ────────────────────────────────────────

"if" @keyword.conditional
"else" @keyword.conditional
"match" @keyword.conditional

"while" @keyword.repeat
"loop" @keyword.repeat
"for" @keyword.repeat
"break" @keyword.repeat
"continue" @keyword.repeat

; ─── Let Bindings ────────────────────────────────────────

"let" @keyword

(let_expression
  pattern: (bind_var
    (identifier) @variable))

; ─── Visibility & Modifiers ──────────────────────────────

"public" @keyword.modifier
(entry_modifier) @keyword.modifier
(inline_modifier) @keyword.modifier
"native" @keyword.modifier

; ─── Spec / Prover ───────────────────────────────────────

"spec" @keyword
"invariant" @keyword
"ensures" @keyword
"requires" @keyword
"aborts_if" @keyword
"modifies" @keyword
"include" @keyword
"pragma" @keyword
"assume" @keyword
"assert" @keyword
"global" @keyword
"exists" @keyword
"forall" @keyword
"emits" @keyword
"apply" @keyword
"schema" @keyword

(spec_block) @keyword

; ─── Move / Copy / Borrow ────────────────────────────────

"move" @keyword
"copy" @keyword

; ─── Operators ───────────────────────────────────────────

(binary_expression
  operator: (_) @operator)

"&" @operator
"&mut" @operator
"*" @operator
"!" @operator

; ─── Punctuation ─────────────────────────────────────────

"(" @punctuation.bracket
")" @punctuation.bracket
"[" @punctuation.bracket
"]" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket
"<" @punctuation.bracket
">" @punctuation.bracket

";" @punctuation.delimiter
"," @punctuation.delimiter
"::" @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter

; ─── Acquires ────────────────────────────────────────────

"acquires" @keyword

; ─── Attributes ──────────────────────────────────────────

(attributes) @attribute

; ─── Parameters ──────────────────────────────────────────

(function_parameter
  name: (identifier) @variable.parameter)

(type_parameter
  name: (identifier) @type.parameter)

; ─── Type references ─────────────────────────────────────

(apply_type
  (name_access_chain
    name: (identifier) @type))

; ─── Identifiers (fallback) ──────────────────────────────

(identifier) @variable
