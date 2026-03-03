; locals.scm — scope and definition tracking for Move on Aptos

; ─── Scopes ──────────────────────────────────────────────

(module_declaration) @local.scope
(function_declaration) @local.scope
(block) @local.scope
(spec_block) @local.scope
(lambda_expression) @local.scope
(for_expression) @local.scope
(while_expression) @local.scope
(loop_expression) @local.scope

; ─── Definitions ─────────────────────────────────────────

(function_declaration
  name: (identifier) @local.definition.function)

(struct_declaration
  name: (identifier) @local.definition.type)

(enum_declaration
  name: (identifier) @local.definition.type)

(constant_declaration
  name: (identifier) @local.definition.constant)

(let_expression
  pattern: (bind_var
    (identifier) @local.definition.var))

(function_parameter
  name: (identifier) @local.definition.parameter)

(type_parameter
  name: (identifier) @local.definition.type)

; ─── References ──────────────────────────────────────────

(name_expression) @local.reference
(name_access_chain) @local.reference
