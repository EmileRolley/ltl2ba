open Parsing
open Ltl
module Al = Alcotest

module To_test = struct
  let parse (formula : string) : formula option =
    let lexbuf = Lexing.from_string formula in
    try Some (Parser.formula Lexer.read lexbuf) with
    | Lexer.Syntax_error _msg -> None
    | Parser.Error -> None
  ;;
end

let al_assert msg = Al.(check bool) msg true

let test_parse_false () =
  let phi_opt = To_test.parse "false" in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (Ltl.Bool false = Option.get phi_opt)
;;

let test_parse_true () =
  let phi_opt = To_test.parse "true" in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (Ltl.Bool true = Option.get phi_opt)
;;

let test_parse_p () =
  let phi_opt = To_test.parse "p" in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (Ltl.Prop "p" = Option.get phi_opt)
;;

let test_parse_p_or_q () =
  let phi_opt = To_test.parse "p | q" in
  let expected_phi = Ltl.(Prop "p" <|> Prop "q") in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (expected_phi = Option.get phi_opt)
;;

let test_parse_priority () =
  let phi_opt = To_test.parse "p | p U !q & q" in
  Ltl.format Format.std_formatter (Option.get phi_opt);
  let expected_phi = Ltl.(Prop "p" <|> (Prop "p" <~> neg (Prop "q") <&> Prop "q")) in
  Ltl.format Format.std_formatter expected_phi;
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (expected_phi = Option.get phi_opt)
;;

let test_parse_p_or_q_and_false () =
  let phi_opt = To_test.parse "(p | q) & false" in
  let expected_phi = Ltl.(Prop "p" <|> Prop "q" <&> Bool false) in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (expected_phi = Option.get phi_opt)
;;

let test_parse_p_or_q_until_false () =
  let phi_opt = To_test.parse "(p | q) U false" in
  let expected_phi = Ltl.(Prop "p" <|> Prop "q" <~> Bool false) in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (expected_phi = Option.get phi_opt)
;;

let test_parse_p_or_q_release_false () =
  let phi_opt = To_test.parse "(p | q) R false" in
  let expected_phi = Ltl.(Prop "p" <|> Prop "q" <^> Bool false) in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (expected_phi = Option.get phi_opt)
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
