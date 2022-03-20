open Parsing
open Ltl
open Test_utils
module Al = Alcotest

module To_test = struct
  let nnf (formula : string) : formula option =
    let lexbuf = Lexing.from_string formula in
    try
      let phi = Parser.formula Lexer.read lexbuf in
      Some (Ltl.nnf phi)
    with
    | Lexer.Syntax_error _msg -> None
    | Parser.Error -> None
  ;;
end

let al_assert_formula_eq = al_assert_formula_eq_according_to_test To_test.nnf

(* Test cases *)

let test_nnf_false () = al_assert_formula_eq "false" Ltl.(Bool false)
let test_nnf_next () = al_assert_formula_eq "X(p)" Ltl.(next (Prop "p"))
let test_nnf_neg_p () = al_assert_formula_eq "!p" Ltl.(neg (Prop "p"))
let test_nnf_neg_neg_p () = al_assert_formula_eq "!!p" Ltl.(Prop "p")
let test_nnf_neg_next () = al_assert_formula_eq "!X(p)" Ltl.(next @@ neg @@ Prop "p")

let test_nnf_neg_or () =
  al_assert_formula_eq "!(p | q)" Ltl.(neg (Prop "p") <&> neg (Prop "q"))
;;

let test_nnf_neg_and () =
  al_assert_formula_eq "!(p & q)" Ltl.(neg (Prop "p") <|> neg (Prop "q"))
;;

let test_nnf_neg_until () =
  al_assert_formula_eq "!(p U q)" Ltl.(neg (Prop "p") <^> neg (Prop "q"))
;;

let test_nnf_neg_release () =
  al_assert_formula_eq "!(p R q)" Ltl.(neg (Prop "p") <~> neg (Prop "q"))
;;

let test_nnf_real1 () =
  al_assert_formula_eq
    "!(!(p U q) R (X p))"
    Ltl.(Prop "p" <~> Prop "q" <~> next (neg (Prop "p")))
;;

let () =
  Al.run
    "LTL to Büchi automata"
    Al.
      [ ( "Negation normal form"
        , [ test_case "nnf(⊥) = ⊥" `Quick test_nnf_false
          ; test_case "nnf(Xp) = Xp" `Quick test_nnf_next
          ; test_case "nnf(¬p) = ¬p" `Quick test_nnf_neg_p
          ; test_case "nnf(¬¬p) = p" `Quick test_nnf_neg_neg_p
          ; test_case "nnf(¬Xp) = X¬p" `Quick test_nnf_neg_next
          ; test_case "nnf(¬(p ∨ q)) = ¬p ∧ ¬q" `Quick test_nnf_neg_or
          ; test_case "nnf(¬(p ∧ q)) = ¬p v ¬q" `Quick test_nnf_neg_and
          ; test_case "nnf(¬(p U q)) = ¬p R ¬q" `Quick test_nnf_neg_until
          ; test_case "nnf(¬(p R q)) = ¬p U ¬q" `Quick test_nnf_neg_release
          ; test_case "nnf(¬(¬(p U q) R (X p))) = (p U q) U (X ¬p))" `Quick test_nnf_real1
          ] )
      ]
;;
