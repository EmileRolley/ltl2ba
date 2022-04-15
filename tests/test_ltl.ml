open Test_utils
open Ltl
module Al = Alcotest

module To_test = struct
  let compare = Ltl.compare
  let is_subformula = Ltl.is_subformula
end

let test_compare_two_equal_formulas () =
  al_assert "should be 0" (To_test.compare (Bool false) (Bool false) = 0)
;;

let test_compare_two_equal_formulas_bis () =
  let phi = Prop "p" <~> Prop "q" => neg (Prop "q") in
  al_assert "should be 0" (To_test.compare phi phi = 0)
;;

let test_compare_two_equal_modulo_symetry () =
  let p = Prop "p"
  and q = Prop "q" in
  al_assert "should be 0" (To_test.compare (p <|> q) (q <|> p) = 0)
;;

let test_compare_two_equal_modulo_symetry_bis () =
  let phi = Prop "p" <^> (Prop "p" <|> Prop "q")
  and psi = Prop "q" <|> Prop "p" <^> Prop "p" in
  al_assert "should be 0" (To_test.compare phi psi = 0)
;;

let test_compare_phi_smaller_than_psi () =
  let psi = Prop "p" in
  let phi = psi <~> Prop "q" => neg (Prop "q") in
  al_assert "should be -1" (To_test.compare phi psi = -1)
;;

let test_compare_phi_bigger_than_psi () =
  let phi = Prop "p" in
  let psi = phi <~> Prop "q" => neg (Prop "q") in
  al_assert "should be 1" (To_test.compare phi psi = 1)
;;

let test_compare_phi_bigger_than_psi_bis () =
  let phi = Prop "b" in
  let psi = Prop "a" in
  al_assert "should be 1" (To_test.compare phi psi = 1)
;;

let test_is_subformula_p_p () =
  let phi = Prop "p" in
  al_assert "should be true" (To_test.is_subformula phi phi)
;;

let test_is_subformula_p_not_p () =
  let phi = Prop "p" in
  al_assert "should be true" (To_test.is_subformula (neg phi) phi)
;;

let test_is_subformula_p_q () =
  let phi = Prop "p" in
  let psi = Prop "q" in
  al_assert "should not be true" (not @@ To_test.is_subformula phi psi)
;;

let test_is_subformula_p_or_q_in_p_U_p_or_q () =
  let psi = Prop "p" <|> Prop "q" in
  let phi = Prop "r" <~> psi in
  al_assert "should be true" (To_test.is_subformula phi psi)
;;

let test_is_subformula_p_or_q_in_q_or_p () =
  let psi = Prop "p" <|> Prop "q" in
  let phi = Prop "q" <|> Prop "p" in
  al_assert "should be true" (To_test.is_subformula phi psi)
;;

let () =
  Al.run
    "LTL basic test"
    Al.
      [ ( "Comparison"
        , [ test_case "⊥ = ⊥" `Quick test_compare_two_equal_formulas
          ; test_case "(p ∨ q) = (q ∨ p)" `Quick test_compare_two_equal_modulo_symetry
          ; test_case
              "p R (p ∨ q) = (q ∨ p) R p"
              `Quick
              test_compare_two_equal_modulo_symetry_bis
          ; test_case "p U q ⇒ ¬q ∧ p" `Quick test_compare_two_equal_formulas_bis
          ; test_case "(p U q ⇒ ¬q ∧ p) > p" `Quick test_compare_phi_smaller_than_psi
          ; test_case "p < (p U q ⇒ ¬q ∧ p) " `Quick test_compare_phi_bigger_than_psi
          ; test_case "a < b " `Quick test_compare_phi_bigger_than_psi_bis
          ] )
      ; ( "Is sub-formula"
        , [ test_case "p ∈ p" `Quick test_is_subformula_p_p
          ; test_case "p ∈ ¬p " `Quick test_is_subformula_p_not_p
          ; test_case
              "(p ∨ q) ∈ (r U (p ∨ q))"
              `Quick
              test_is_subformula_p_or_q_in_p_U_p_or_q
          ; test_case "(p ∨ q) ∈ (q ∨ p)" `Quick test_is_subformula_p_or_q_in_q_or_p
          ; test_case "p ∉ q " `Quick test_is_subformula_p_q
          ] )
      ]
;;
