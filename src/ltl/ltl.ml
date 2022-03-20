module Formula = struct
  type t =
    | Bool of bool
    | Prop of string
    | Uop of uop * t
    | Bop of t * bop * t

  and uop =
    | Not
    | Next

  and bop =
    | Or
    | And
    | Until
    | Release

  let not phi = Uop (Not, phi)
  let next phi = Uop (Next, phi)
  let ( <|> ) phi psi = Bop (phi, Or, psi)
  let ( <&> ) phi psi = Bop (phi, And, psi)
  let ( <~> ) phi psi = Bop (phi, Until, psi)
  let ( <^> ) phi psi = Bop (phi, Release, psi)

  let rec format fmt = function
    | Bool b -> Format.fprintf fmt "%s" (if b then "⊤" else "⊥")
    | Prop p -> Format.fprintf fmt "%s" p
    | Uop (o, f) -> Format.fprintf fmt "%s(%a)" (uop_to_string o) format f
    | Bop (f, o, f') ->
      Format.fprintf fmt "(%a %s %a)" format f (bop_to_string o) format f'

  and uop_to_string = function
    | Not -> "¬"
    | Next -> "X"

  and bop_to_string = function
    | Or -> "∨"
    | And -> "∧"
    | Until -> "U"
    | Release -> "R"
  ;;
end
