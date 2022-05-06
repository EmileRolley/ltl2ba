open Parsing
open Core
open Ltl
open Automata
open Algorithm
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

  let next : state -> state = Algorithm.next
  let sigma : state -> FormulaSet.t = Algorithm.sigma
  let is_reduced : state -> bool = Algorithm.is_reduced
  let is_maximal : formula -> state -> bool = Algorithm.is_maximal
  let red : state -> red_states = Algorithm.red
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

let test_nnf_example1 () =
  al_assert_formula_eq "p U Xq" Ltl.(Prop "p" <~> next (Prop "q"))
;;

let test_nnf_not_F () = al_assert_formula_eq "!Fq" Ltl.(Bool false <^> neg (Prop "q"))

let test_nnf_F_implies () =
  al_assert_formula_eq "Fq => p" Ltl.(Bool false <^> neg (Prop "q") <|> Prop "p")
;;

let test_nnf_neg_implies () =
  al_assert_formula_eq "!(q => p)" Ltl.(Prop "q" <&> neg (Prop "p"))
;;

let test_nnf_neg_globally () =
  al_assert_formula_eq "!G(q)" Ltl.(Bool true <~> neg (Prop "q"))
;;

let test_nnf_example2 () =
  al_assert_formula_eq
    "G(p => XFq)"
    Ltl.(Bool false <^> (neg (Prop "p") <|> next (Bool true <~> Prop "q")))
;;

let test_next_next_p () =
  let next_z = FormulaSet.singleton Ltl.(next (Prop "p"))
  and z = FormulaSet.singleton (Ltl.Prop "p") in
  al_assert "should be equals" (FormulaSet.equal (To_test.next next_z) z)
;;

let test_next_p () =
  let z = FormulaSet.singleton Ltl.(Prop "p") in
  al_assert "should be equals" FormulaSet.(equal (To_test.next z) empty)
;;

let test_next_multiple_formulas () =
  let next_z =
    FormulaSet.of_list Ltl.[ next (Prop "p"); next (next (Prop "q")); Bool false ]
  and z = FormulaSet.of_list Ltl.[ Prop "p"; next (Prop "q") ] in
  al_assert "should be equals" (FormulaSet.equal (To_test.next next_z) z)
;;

let test_next_empty_set () =
  al_assert "should be equals" FormulaSet.(equal (To_test.next empty) empty)
;;

let test_is_reduced_empty () =
  al_assert "should be reduced" (To_test.is_reduced FormulaSet.empty)
;;

let test_is_reduced_false () =
  al_assert
    "should not be reduced"
    (not @@ To_test.is_reduced (FormulaSet.singleton Ltl.(Bool false)))
;;

let test_is_reduced_true () =
  al_assert
    "should be reduced"
    (To_test.is_reduced (FormulaSet.singleton Ltl.(Bool true)))
;;

let test_is_reduced_p () =
  al_assert "should be reduced" (To_test.is_reduced (FormulaSet.singleton Ltl.(Prop "p")))
;;

let test_is_reduced_p_and_not_p () =
  let p = Ltl.Prop "p" in
  let not_p = Ltl.neg p in
  al_assert
    "should not be reduced"
    (not @@ To_test.is_reduced (FormulaSet.of_list [ p; not_p ]))
;;

let test_is_reduced_p_and_not_q () =
  let p = Ltl.Prop "p" in
  let not_q = Ltl.(neg (Prop "q")) in
  al_assert "should be reduced" (To_test.is_reduced (FormulaSet.of_list [ p; not_q ]))
;;

let test_is_reduced_p_and_not_q_and_next_p () =
  let p = Ltl.Prop "p" in
  let not_q = Ltl.(neg (Prop "q")) in
  let next_p = Ltl.next p in
  al_assert
    "should be reduced"
    (To_test.is_reduced (FormulaSet.of_list [ p; not_q; next_p ]))
;;

let test_is_reduced_p_and_complex_formula () =
  let p = Ltl.Prop "p" in
  let p_U_Xq = Ltl.(Prop "p" <~> next (Prop "q")) in
  al_assert
    "should not be reduced"
    (not @@ To_test.is_reduced (FormulaSet.of_list [ p; p_U_Xq ]))
;;

let test_is_maximal_phi_not_in_state () =
  al_assert "should be false" (not @@ To_test.is_maximal (Bool true) FormulaSet.empty)
;;

let test_is_maximal_true_in_aUq () =
  let state = FormulaSet.of_list [ Bool true; Ltl.(Prop "p" <~> Prop "q") ] in
  al_assert "should be true" (To_test.is_maximal (Bool true) state)
;;

let test_is_maximal_p_in_p () =
  let p = Prop "p" in
  al_assert "should be true" (To_test.is_maximal p (FormulaSet.singleton p))
;;

let test_is_maximal_bug () =
  let phi = Bool true <~> Prop "q" in
  let psi = Bool false <^> (neg @@ Prop "p" <|> phi) in
  let state = FormulaSet.of_list [ phi; psi ] in
  al_assert "should be false" (not @@ To_test.is_maximal phi state);
  al_assert "should be true" (To_test.is_maximal psi state)
;;

let test_is_not_maximal () =
  let p = Prop "p"
  and q = Prop "q" in
  let state = FormulaSet.of_list [ p; q; q <~> (p <^> q) ] in
  al_assert "should not be true" (not @@ To_test.is_maximal p state)
;;

let test_sigma_empty () =
  al_assert "should be equals" FormulaSet.(equal empty (To_test.sigma empty))
;;

let test_sigma_p () =
  let state = FormulaSet.singleton (Prop "p") in
  al_assert "should be equals" FormulaSet.(equal state (To_test.sigma state))
;;

let test_sigma_next_q () =
  let state = FormulaSet.singleton (Ltl.next (Prop "q")) in
  al_assert "should be equals" FormulaSet.(equal empty (To_test.sigma state))
;;

let test_sigma_p_and_neg_q () =
  let state = FormulaSet.of_list [ Ltl.next (Prop "q"); Prop "p"; neg (Prop "q") ] in
  al_assert
    "should be equals"
    FormulaSet.(equal (of_list [ Prop "p"; neg (Prop "q") ]) (To_test.sigma state))
;;

let test_red_empty () =
  al_assert "should be empty" (StateSet.empty = (To_test.red FormulaSet.empty).all)
;;

let test_red_already_reduced () =
  let state = FormulaSet.of_list [ Prop "p"; neg (Prop "q"); Ltl.next (Prop "p") ] in
  let expected = StateSet.singleton state in
  al_assert "should be equals" (expected = (To_test.red state).all)
;;

let test_red_disjunction () =
  let state = FormulaSet.of_list [ Prop "p"; Prop "p" <|> Prop "q" ] in
  let expected =
    StateSet.of_list
      [ FormulaSet.singleton (Prop "p"); FormulaSet.of_list [ Prop "p"; Prop "q" ] ]
  in
  al_assert "should be equals" StateSet.(equal expected (To_test.red state).all)
;;

let test_red_conjunction () =
  let state = FormulaSet.of_list [ Prop "p"; Prop "p" <&> Prop "q" ] in
  let expected = StateSet.of_list [ FormulaSet.of_list [ Prop "p"; Prop "q" ] ] in
  al_assert "should be equals" StateSet.(equal expected (To_test.red state).all)
;;

let test_red_false () =
  let state = FormulaSet.of_list [ Bool false; Prop "p" <&> Prop "q" ] in
  al_assert "should be equals" StateSet.(equal empty (To_test.red state).all)
;;

let test_red_next () =
  let state =
    FormulaSet.of_list
      Ltl.[ next (Bool false <^> (neg (Prop "p") <|> next (Bool true <~> Prop "q"))) ]
  in
  let expected = StateSet.of_list [ state ] in
  al_assert "should be equals" StateSet.(equal expected (To_test.red state).all)
;;

let test_is_reduced_bug () =
  let state =
    FormulaSet.of_list
      Ltl.[ next (Bool false <^> (neg (Prop "p") <|> next (Bool true <~> Prop "q"))) ]
  in
  al_assert "should be true" (To_test.is_reduced state)
;;

let test_red_release () =
  let state = FormulaSet.of_list [ Prop "p"; Prop "p" <^> Prop "q" ] in
  let expected =
    StateSet.of_list
      FormulaSet.
        [ of_list [ Prop "p"; Prop "q" ]
        ; of_list [ Prop "p"; Ltl.next (Prop "p" <^> Prop "q"); Prop "q" ]
        ]
  in
  al_assert "should be equals" StateSet.(equal expected (To_test.red state).all)
;;

let test_red_until () =
  let phi = Prop "p" <~> Ltl.next (Prop "q") in
  let expected =
    StateSet.of_list
      FormulaSet.[ singleton (Ltl.next (Prop "q")); of_list [ Prop "p"; Ltl.next phi ] ]
  in
  al_assert
    "should be equals"
    StateSet.(equal expected (To_test.red (FormulaSet.singleton phi)).all)
;;

(** Red({p U (p v Xq)}) = { {p}, {Xq}, {X(p U (p v Xq)), p} }*)
let test_red_multiple_lvl () =
  let phi = Prop "p" <~> (Prop "p" <|> Ltl.next (Prop "q")) in
  let expected =
    StateSet.of_list
      FormulaSet.
        [ singleton (Prop "p")
        ; singleton (Ltl.next (Prop "q"))
        ; of_list [ Prop "p"; Ltl.next phi ]
        ]
  in
  al_assert
    "should be equals"
    StateSet.(equal expected (To_test.red (FormulaSet.singleton phi)).all)
;;

let test_red_alpha_empty () =
  al_assert "should be empty" (FormulaMap.empty = (To_test.red FormulaSet.empty).marked_by)
;;

let test_red_alpha_ex1 () =
  let phi = Prop "p" <~> Ltl.next (Prop "q") in
  let expected_marked_by_phi =
    StateSet.singleton @@ FormulaSet.of_list [ Ltl.next phi; Prop "p" ]
  in
  let expected_map = FormulaMap.singleton phi expected_marked_by_phi in
  let actual = To_test.red (FormulaSet.singleton phi) in
  al_assert "should be equal" (expected_map = actual.marked_by)
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
          ; test_case "nnf(¬(q => p)) = q ∧ ¬p" `Quick test_nnf_neg_implies
          ; test_case "nnf(¬G(p)) = ⊤ U ¬p" `Quick test_nnf_neg_globally
          ; test_case "nnf(p U Xq) = p U Xq" `Quick test_nnf_example1
          ; test_case "nnf(¬Fq) = (⊥ R ¬q)" `Quick test_nnf_not_F
          ; test_case "nnf(Fq => p) = (⊥ R ¬q) v p" `Quick test_nnf_F_implies
          ; test_case "nnf(G(¬p ∨ XFq) = ?" `Quick test_nnf_example2
          ; test_case "nnf(¬(¬(p U q) R (X p))) = (p U q) U (X ¬p))" `Quick test_nnf_real1
          ] )
      ; ( "Next"
        , [ test_case "next({Xp}) = {p}" `Quick test_next_next_p
          ; test_case "next({p}) = {}" `Quick test_next_p
          ; test_case "next({Xp, XXq, ⊥}) = {p, Xq}" `Quick test_next_multiple_formulas
          ; test_case "next({}) = {}" `Quick test_next_empty_set
          ] )
      ; ( "State is reduced"
        , [ test_case "is_reduced({})" `Quick test_is_reduced_empty
          ; test_case "is_reduced({⊤})" `Quick test_is_reduced_true
          ; test_case "is_reduced({p})" `Quick test_is_reduced_p
          ; test_case "is_reduced({p, ¬q})" `Quick test_is_reduced_p_and_not_q
          ; test_case
              "is_reduced({p, ¬q, Xp}) "
              `Quick
              test_is_reduced_p_and_not_q_and_next_p
          ; test_case "not is_reduced({p, ¬p})" `Quick test_is_reduced_p_and_not_p
          ; test_case "not is_reduced({⊥})" `Quick test_is_reduced_false
          ; test_case
              "not is_reduced({p, (p U Xq)})"
              `Quick
              test_is_reduced_p_and_complex_formula
          ; test_case "not is_reduced(X(⊥ R (¬p ∨ X(⊤ U q))))" `Quick test_is_reduced_bug
          ] )
      ; ( "Formula is maximal in state"
        , [ test_case "not is_maximal(⊤, {})" `Quick test_is_maximal_phi_not_in_state
          ; test_case "not is_maximal(p, {p, q, q U (p R q)})" `Quick test_is_not_maximal
          ; test_case "is_maximal(⊤, {⊤, a U q})" `Quick test_is_maximal_true_in_aUq
          ; test_case "is_maximal(p, {p})" `Quick test_is_maximal_p_in_p
          ; test_case "is_maximal bug #1" `Quick test_is_maximal_bug
          ] )
      ; ( "Σ(Z)"
        , [ test_case "sigma({}) = {}" `Quick test_sigma_empty
          ; test_case "sigma({p}) = {p}" `Quick test_sigma_p
          ; test_case "sigma({Xq}) = {}" `Quick test_sigma_next_q
          ; test_case "sigma({Xq, p, ¬q}) = {}" `Quick test_sigma_p_and_neg_q
          ] )
      ; ( "Calculate Red(Z)"
        , [ test_case "red({}) = {}" `Quick test_red_empty
          ; test_case "red({p, ¬q, Xp}) = { {p, ¬q, Xp} }" `Quick test_red_already_reduced
          ; test_case "red({⊥, p, p v q}) = {}" `Quick test_red_disjunction
          ; test_case "red({p, p ∧ q}) = { {p, q} }" `Quick test_red_conjunction
          ; test_case "red({p, p ∧ q}) = { {p, q} }" `Quick test_red_false
          ; test_case "red({X(p R q)}) = { {X(p R q)} }" `Quick test_red_next
          ; test_case
              "red({p, p R q}) = { {p, q}, {X(p R q), q} }"
              `Quick
              test_red_release
          ; test_case "red({p U Xq}) = { {Xq}, {X(p U Xq), p} }" `Quick test_red_until
          ; test_case
              "red({p U (p v Xq)}) = { {p}, {Xq}, {X(p U (p v Xq)), p} }"
              `Quick
              test_red_multiple_lvl
          ] )
      ; ( "Calculate Red_α(Z)"
        , [ test_case "red_alpha({}) = {}" `Quick test_red_alpha_empty
          ; test_case "red_alpha({p U Xq}) = { {X(p U Xq), p} }" `Quick test_red_alpha_ex1
          ] )
      ]
;;
