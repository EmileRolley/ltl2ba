open Test_utils
module Al = Alcotest

module To_test = struct
  let compare = Ltl.compare
end

let test_compare_two_equal_formulas () =
  al_assert "should be 0" Ltl.(To_test.compare (Bool false) (Bool false) = 0)
;;

let test_compare_two_equal_formulas_bis () =
  let phi = Ltl.(Prop "p" <~> Prop "q" => neg (Prop "q")) in
  al_assert "should be 0" (To_test.compare phi phi = 0)
;;

let test_compare_phi_smaller_than_psi () =
  let phi = Ltl.(Prop "p" <~> Prop "q" => neg (Prop "q")) in
  let psi = Ltl.(Prop "p") in
  al_assert "should be -1" (To_test.compare phi psi = -1)
;;

let test_compare_phi_bigger_than_psi () =
  let phi = Ltl.(Prop "p") in
  let psi = Ltl.(Prop "p" <~> Prop "q" => neg (Prop "q")) in
  al_assert "should be 1" (To_test.compare phi psi = 1)
;;

let test_compare_phi_bigger_than_psi_bis () =
  let phi = Ltl.(Prop "b") in
  let psi = Ltl.(Prop "a") in
  al_assert "should be 1" (To_test.compare phi psi = 1)
;;

let () =
  Al.run
    "LTL basic test"
    Al.
      [ ( "Comparison"
        , [ test_case "⊥ = ⊥" `Quick test_compare_two_equal_formulas
          ; test_case "p U q ⇒ ¬q ∧ p" `Quick test_compare_two_equal_formulas_bis
          ; test_case "(p U q ⇒ ¬q ∧ p) > p" `Quick test_compare_phi_smaller_than_psi
          ; test_case "p < (p U q ⇒ ¬q ∧ p) " `Quick test_compare_phi_bigger_than_psi
          ; test_case "a < b " `Quick test_compare_phi_bigger_than_psi_bis
          ] )
      ]
;;
