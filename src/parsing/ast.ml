type formula =
  | Bool of bool
  | Prop of string
  | Uop of uop * formula
  | Bop of formula * bop * formula

and uop = Not | Next
and bop = Or | And | Until

let rec formula_to_string : formula -> string = function
  | Bool b -> if b then "⊤" else "⊥"
  | Prop p -> p
  | Uop (o, f) ->
      Printf.sprintf "%s(%s)" (uop_to_string o) (formula_to_string f)
  | Bop (f, o, f') ->
      Printf.sprintf "(%s %s %s)" (formula_to_string f) (bop_to_string o)
        (formula_to_string f')

and uop_to_string = function Not -> "¬" | Next -> "X"
and bop_to_string = function Or -> "∨" | And -> "∧" | Until -> "U"
