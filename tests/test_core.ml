open Core
open Algorithm
open Test_utils
module Al = Alcotest

module To_test = struct
  let next : state -> state = Algorithm.next
  let is_reduced : state -> bool = Algorithm.is_reduced
end

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

let () =
  Al.run
    "Core algorithm"
    Al.
      [ ( "next(Z)"
        , [ test_case "next({Xp}) = {p}" `Quick test_next_next_p
          ; test_case "next({p}) = {}" `Quick test_next_p
          ; test_case "next({Xp, XXq, ⊥}) = {p, Xq}" `Quick test_next_multiple_formulas
          ; test_case "next({}) = {}" `Quick test_next_empty_set
          ] )
      ; ( "is_reduced"
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
          ] )
      ]
;;
