open Parsing
open Ltl
open Test_utils
module Al = Alcotest

module To_test = struct
  let parse (formula : string) : formula option =
    let lexbuf = Lexing.from_string formula in
    try Some (Parser.formula Lexer.read lexbuf) with
    | Lexer.Syntax_error _msg -> None
    | Parser.Error -> None
  ;;
end

let al_assert_formula_eq = al_assert_formula_eq_according_to_test To_test.parse

(* Test cases *)

let test_parse_false () = al_assert_formula_eq "false" (Ltl.Bool false)
let test_parse_true () = al_assert_formula_eq "true" (Ltl.Bool true)
let test_parse_p () = al_assert_formula_eq "p" (Ltl.Prop "p")
let test_parse_p_or_q () = al_assert_formula_eq "p | q" Ltl.(Prop "p" <|> Prop "q")

let test_parse_priority () =
  al_assert_formula_eq
    "p | p U !q & q"
    Ltl.(Prop "p" <|> (Prop "p" <~> neg (Prop "q") <&> Prop "q"))
;;

let test_parse_p_or_q_and_false () =
  al_assert_formula_eq "(p | q) & false" Ltl.(Prop "p" <|> Prop "q" <&> Bool false)
;;

let test_parse_p_or_q_until_false () =
  al_assert_formula_eq "(p | q) U false" Ltl.(Prop "p" <|> Prop "q" <~> Bool false)
;;

let test_parse_p_or_q_release_false () =
  al_assert_formula_eq "(p | q) R false" Ltl.(Prop "p" <|> Prop "q" <^> Bool false)
;;

let () =
  Al.run
    "LTL parsing"
    Al.
      [ ( "Propositional formulas"
        , [ test_case "φ := ⊥" `Quick test_parse_false
          ; test_case "φ := ⊤" `Quick test_parse_true
          ; test_case "φ := p" `Quick test_parse_p
          ; test_case "φ := p ∨ q" `Quick test_parse_p_or_q
          ; test_case "φ := (p ∨ q) ∧ ⊥" `Quick test_parse_p_or_q_and_false
          ; test_case "φ := p ∨ p U ¬q ∧ q" `Quick test_parse_priority
          ] )
      ; ( "LTL formulas"
        , [ test_case "φ := (p ∨ q) U ⊥" `Quick test_parse_p_or_q_until_false
          ; test_case "φ := (p ∨ q) R ⊥" `Quick test_parse_p_or_q_release_false
          ] )
      ]
;;
