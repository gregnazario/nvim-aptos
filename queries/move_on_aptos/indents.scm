; indents.scm — auto-indentation rules for Move on Aptos

[
  (module_declaration)
  (function_declaration)
  (struct_declaration)
  (enum_declaration)
  (spec_block)
  (block)
  (if_expression)
  (while_expression)
  (loop_expression)
  (for_expression)
  (match_expression)
] @indent.begin

[
  "}"
  ")"
  "]"
] @indent.end

[
  "{"
  "("
  "["
] @indent.branch
