type formula =
  | Bool of bool
  | Prop of string
  | Not of formula
  | Next of formula
  | Until of formula * formula
  | Or of formula * formula
  | And of formula * formula

let rec formula_to_string : formula -> string = function
  | Bool b -> if b then "⊤" else "⊥"
  | Prop p -> p
  | Not f -> Printf.sprintf "¬(%s)" (formula_to_string f)
  | Next f -> Printf.sprintf "X(%s)" (formula_to_string f)
  | Until (f, f') ->
      Printf.sprintf "(%s U %s)" (formula_to_string f) (formula_to_string f')
  | Or (f, f') ->
      Printf.sprintf "(%s ∨ %s)" (formula_to_string f) (formula_to_string f')
  | And (f, f') ->
      Printf.sprintf "(%s ∧ %s)" (formula_to_string f) (formula_to_string f')
