type formula =
  | Bool of bool
  | Prop of string
  | Uop of uop * formula
  | Bop of formula * bop * formula

and uop =
  | Not
  | Next
  | Finally
  | Globally

and bop =
  | Or
  | And
  | Until
  | Release
  | Implies

let neg phi = Uop (Not, phi)
let next phi = Uop (Next, phi)
let finally phi = Uop (Finally, phi)
let ( <|> ) phi psi = Bop (phi, Or, psi)
let ( <&> ) phi psi = Bop (phi, And, psi)
let ( <~> ) phi psi = Bop (phi, Until, psi)
let ( <^> ) phi psi = Bop (phi, Release, psi)
let ( => ) phi psi = Bop (phi, Implies, psi)

let rec format fmt = function
  | Bool b -> Format.fprintf fmt "%s" (if b then "⊤" else "⊥")
  | Prop p -> Format.fprintf fmt "%s" p
  | Uop (o, f) -> Format.fprintf fmt "%s%a" (uop_to_string o) format f
  | Bop (f, o, f') -> Format.fprintf fmt "(%a %s %a)" format f (bop_to_string o) format f'

and uop_to_string = function
  | Not -> "¬"
  | Next -> "X"
  | Finally -> "F"
  | Globally -> "G"

and bop_to_string = function
  | Or -> "∨"
  | And -> "∧"
  | Until -> "U"
  | Release -> "R"
  | Implies -> "⇒"
;;

let to_string phi =
  format Format.str_formatter phi;
  Format.flush_str_formatter ()
;;

let compare phi psi = String.compare (to_string phi) (to_string psi)

let rec nnf = function
  | (Bool _ | Prop _) as phi -> phi
  | Bop (_, Implies, _) as phi -> nnf (normalize phi)
  | Bop (phi, o, psi) -> Bop (nnf phi, o, nnf psi)
  | Uop (op, phi') as phi ->
    (match op with
    | Next -> next (nnf phi')
    | Finally | Globally -> nnf (normalize phi)
    | Not ->
      (match phi' with
      | Bool b -> Bool (not b)
      | Prop _ as p -> neg p (* leaf reached, nnf(¬p) = ¬p *)
      | Uop ((Finally | Globally), _) -> nnf (normalize phi)
      | Uop (Next, psi) ->
        (* nnf(¬Xφ) = X(nnf(¬φ)) *)
        next (nnf (neg psi))
      | Uop (Not, psi) ->
        (* nnf(¬¬φ) = nnf(φ) *)
        nnf psi
      | Bop (_, Implies, _) -> nnf (normalize phi)
      | Bop (psi, o, psi') -> get_dual o (nnf (neg psi)) (nnf (neg psi'))))

(** Returns the equivalent function in its normalized form: only U and R binary temporal
    operators are allowed in the NNF. *)
and normalize = function
  | Uop (Finally, phi) -> Bool true <~> phi
  | Uop (Globally, phi) -> Bool false <^> phi
  | Bop (phi, Implies, psi) -> neg phi <|> psi
  | p -> p

and get_dual = function
  | Or -> (* nnf(¬(φ ∨ ψ)) = nnf(¬φ) ∧ nnf(¬ψ) *) ( <&> )
  | And -> (* nnf(¬(φ ∧ ψ)) = nnf(¬φ) ∨ nnf(¬ψ) *) ( <|> )
  | Until -> (* nnf(¬(φ U ψ)) = nnf(¬φ) R nnf(¬ψ) *) ( <^> )
  | Release -> (* nnf(¬(φ R ψ)) = nnf(¬φ) U nnf(¬ψ) *) ( <~> )
  | Implies -> failwith "should never be reached"
;;
