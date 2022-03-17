type formula =
  | Bool of bool
  | Prop of string
  | Not of formula
  | Next of formula
  | Until of formula * formula
  | Or of formula * formula
  | And of formula * formula
