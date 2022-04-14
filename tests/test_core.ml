open Core
open Algorithm
open Test_utils
module Al = Alcotest

module To_test = struct
  let next : state -> state = Algorithm.next
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
      ]
;;
