type formula =
  | Bool of bool
  | Prop of string
  | Uop of uop * formula
  | Bop of formula * bop * formula

and uop =
  | Not
  | Next

and bop =
  | Or
  | And
  | Until
  | Release

let neg phi = Uop (Not, phi)
let next phi = Uop (Next, phi)
let ( <|> ) phi psi = Bop (phi, Or, psi)
let ( <&> ) phi psi = Bop (phi, And, psi)
let ( <~> ) phi psi = Bop (phi, Until, psi)
let ( <^> ) phi psi = Bop (phi, Release, psi)

let rec format fmt = function
  | Bool b -> Format.fprintf fmt "%s" (if b then "⊤" else "⊥")
  | Prop p -> Format.fprintf fmt "%s" p
  | Uop (o, f) -> Format.fprintf fmt "%s(%a)" (uop_to_string o) format f
  | Bop (f, o, f') -> Format.fprintf fmt "(%a %s %a)" format f (bop_to_string o) format f'

and uop_to_string = function
  | Not -> "¬"
  | Next -> "X"

and bop_to_string = function
  | Or -> "∨"
  | And -> "∧"
  | Until -> "U"
  | Release -> "R"
;;

let rec nnf = function
  | (Bool _ | Prop _) as p -> p
  | Uop (Next, phi) -> next (nnf phi)
  | Bop (phi, o, psi) -> Bop (nnf phi, o, nnf psi)
  | Uop (Not, phi) ->
    (match phi with
    | Bool b -> Bool (not b)
    | Prop _ as p -> neg p (* leaf reached, nnf(¬p) = ¬p *)
    | Uop (Next, phi) ->
      (* nnf(¬Xφ) = X(nnf(¬φ)) *)
      next (nnf (neg phi))
    | Uop (Not, phi) ->
      (* nnf(¬¬φ) = nnf(φ) *)
      nnf phi
    | Bop (phi, o, psi) -> get_dual o (nnf (neg phi)) (nnf (neg psi)))

and get_dual = function
  | Or -> (* nnf(¬(φ ∨ ψ)) = nnf(¬φ) ∧ nnf(¬ψ) *) ( <&> )
  | And -> (* nnf(¬(φ ∧ ψ)) = nnf(¬φ) ∨ nnf(¬ψ) *) ( <|> )
  | Until -> (* nnf(¬(φ U ψ)) = nnf(¬φ) R nnf(¬ψ) *) ( <^> )
  | Release -> (* nnf(¬(φ R ψ)) = nnf(¬φ) U nnf(¬ψ) *) ( <~> )
;;
