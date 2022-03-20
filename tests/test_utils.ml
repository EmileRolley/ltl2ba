open Ltl
module Al = Alcotest

let al_assert (msg : string) : bool -> unit = Al.(check bool) msg true

let al_assert_formula_eq_according_to_test
    (to_test : string -> formula option) (phi_s : string) (phi_expected : formula)
    : unit
  =
  let phi_opt = to_test phi_s in
  al_assert "should parsed" (Option.is_some phi_opt);
  al_assert "should be equal" (phi_expected = Option.get phi_opt)
;;
