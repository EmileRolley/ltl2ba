open Parsing
open Ltl
module Al = Alcotest

module To_test = struct
  let nnf (formula : string) =
    let lexbuf = Lexing.from_string formula in
    try
      let phi = Parser.formula Lexer.read lexbuf in
      Some (Formula.nnf phi)
    with
    | Lexer.Syntax_error _msg -> None
    | Parser.Error -> None
  ;;
end

let al_assert msg = Al.(check bool) msg true

let test_nnf_false () =
  let nnf_phi_opt = To_test.nnf "false" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert "should be equal" (Formula.Bool false = Option.get nnf_phi_opt)
;;

let test_nnf_next () =
  let nnf_phi_opt = To_test.nnf "X(p)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert "should be equal" (Formula.(next @@ Prop "p") = Option.get nnf_phi_opt)
;;

let test_nnf_neg_p () =
  let nnf_phi_opt = To_test.nnf "!p" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert "should be equal" (Formula.(neg @@ Prop "p") = Option.get nnf_phi_opt)
;;

let test_nnf_neg_neg_p () =
  let nnf_phi_opt = To_test.nnf "!!p" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert "should be equal" (Formula.(Prop "p") = Option.get nnf_phi_opt)
;;

let test_nnf_neg_next () =
  let nnf_phi_opt = To_test.nnf "!X(p)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert "should be equal" (Formula.(next @@ neg @@ Prop "p") = Option.get nnf_phi_opt)
;;

let test_nnf_neg_or () =
  let nnf_phi_opt = To_test.nnf "!(p | q)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert
    "should be equal"
    (Formula.(neg (Prop "p") <&> neg (Prop "q")) = Option.get nnf_phi_opt)
;;

let test_nnf_neg_and () =
  let nnf_phi_opt = To_test.nnf "!(p & q)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert
    "should be equal"
    (Formula.(neg (Prop "p") <|> neg (Prop "q")) = Option.get nnf_phi_opt)
;;

let test_nnf_neg_until () =
  let nnf_phi_opt = To_test.nnf "!(p U q)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert
    "should be equal"
    (Formula.(neg (Prop "p") <^> neg (Prop "q")) = Option.get nnf_phi_opt)
;;

let test_nnf_neg_release () =
  let nnf_phi_opt = To_test.nnf "!(p R q)" in
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert
    "should be equal"
    (Formula.(neg (Prop "p") <~> neg (Prop "q")) = Option.get nnf_phi_opt)
;;

let test_nnf_real1 () =
  let nnf_phi_opt = To_test.nnf "!(!(p U q) R (X p))" in
  let expected = Formula.(Prop "p" <~> Prop "q" <~> next (neg (Prop "p"))) in
  Formula.format Format.std_formatter expected;
  print_endline "done";
  Formula.format Format.std_formatter (Option.get nnf_phi_opt);
  al_assert "should parsed" (Option.is_some nnf_phi_opt);
  al_assert
    "should be equal"
    (Formula.(Prop "p" <~> Prop "q" <~> next (neg (Prop "p"))) = Option.get nnf_phi_opt)
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
