open Ltl
open Automata

type red_states =
  { all : StateSet.t
  ; unmarked_by : StateSet.t FormulaMap.t
  }

(* TODO: could factorized with [state_to_string]. *)
let red_states_to_string (states : red_states) : string =
  Printf.sprintf
    "{ %s }"
    (StateSet.fold
       (fun f s ->
         s ^ (if 0 <> String.length s then ", " else "") ^ state_to_string ~quote:true f)
       states.all
       "")
;;

let next state =
  FormulaSet.filter_map
    (function
      | Uop (Next, phi) -> Some phi
      | _ -> None)
    state
;;

let sigma state =
  FormulaSet.(
    fold
      (fun phi formula_set ->
        match phi with
        | Prop _ | Uop (Not, Prop _) -> add phi formula_set
        | _ -> formula_set)
      state
      empty)
;;

let formula_is_reduced = function
  | Bool b ->
    (* ⊥ ∉ Z *)
    b
  | Prop _ | Uop (Not, Prop _) | Uop (Next, _) ->
    (* formulas of Z are of the form: p, ¬q, or Xα *)
    true
  | _ -> false
;;

let is_reduced state =
  state
  |> FormulaSet.for_all (function
         | Bool b ->
           (* ⊥ ∉ Z *)
           b
         | Prop p ->
           (* ∀.p ∈ AP, \{p, ¬p\} ⊈ Z *)
           FormulaSet.for_all
             (function
               | Uop (Not, Prop q) -> p <> q
               | _ -> true)
             state
         | Uop (Not, Prop _) | Uop (Next, _) ->
           (* formulas of Z are of the form: p, ¬q, or Xα *)
           true
         | _ -> false)
;;

let is_maximal phi state =
  let open FormulaSet in
  if not (mem phi state)
  then false
  else (
    let s = remove phi state in
    is_empty s || (not @@ exists (fun psi -> Ltl.(is_subformula psi phi)) s))
;;

let red state =
  let open StateSet in
  (* Reduces first maximal not reduced subset of [tmp_state] *)
  let reduce_state (tmp_state : state) : red_states =
    Printf.printf "\tReducing state: %s\n" (state_to_string tmp_state);
    (* Finds first maximal not reduced subset of [tmp_state], if exists, otherwise,
       returns simply the first formula of [tmp_state]. *)
    let unreduced_subset =
      tmp_state |> FormulaSet.filter (fun phi -> not (formula_is_reduced phi))
    in
    let alpha =
      unreduced_subset
      |> FormulaSet.filter (fun phi -> is_maximal phi unreduced_subset)
      |> FormulaSet.choose
    in
    Printf.printf "\tMaximal unreduced formula: %s\n" (to_string alpha);
    let tmp_state = FormulaSet.remove alpha tmp_state in
    match alpha with
    | Bop (a1, Or, a2) ->
      (* If α = α1 ∨ α2, Y ⟶ Z ∪ {α1} and Y ⟶ Z ∪ {α2} *)
      { all =
          empty |> add FormulaSet.(add a1 tmp_state) |> add FormulaSet.(add a2 tmp_state)
      ; unmarked_by = FormulaMap.empty
      }
    | Bop (a1, And, a2) ->
      (* If α = α1 ∧ α2, Y ⟶ Z ∪ {α1, α2} *)
      { all = empty |> add FormulaSet.(tmp_state |> add a1 |> add a2)
      ; unmarked_by = FormulaMap.empty
      }
    | Bop (a1, Release, a2) ->
      (* If α = α1 R α2, Y ⟶ Z ∪ {α1, α2} and Y ⟶ Z ∪ {Xα, α2} *)
      { all =
          empty
          |> add FormulaSet.(tmp_state |> add a1 |> add a2)
          |> add FormulaSet.(tmp_state |> add (Ltl.next alpha) |> add a2)
      ; unmarked_by = FormulaMap.empty
      }
    | Bop (a1, Until, a2) ->
      (* If α = α1 U α2, Y ⟶ Z ∪ {α2} and Y ⟶α Z ∪ {Xα, α1} *)
      { all =
          empty
          |> add FormulaSet.(add a2 tmp_state)
          |> add FormulaSet.(tmp_state |> add (Ltl.next alpha) |> add a1)
      ; unmarked_by = FormulaMap.empty
      }
    | _ ->
      failwith
        " should never be reached, as [alpha] is the maximal not reduced subset of [state]\n"
  in
  (* Reduces the state in [states] until all states are reduced, meaning that [states]
     contains all the leafs of the temporary oriented graph built from [state] *)
  let rec reduce (states : red_states) : red_states =
    let contains_phi_and_not_phi state : bool =
      FormulaSet.exists (fun phi -> FormulaSet.mem (neg phi) state) state
    in
    if for_all is_reduced states.all
    then states
    else (
      let new_states =
        states.all
        |> StateSet.filter (fun state ->
               not (FormulaSet.mem (Bool false) state || contains_phi_and_not_phi state))
        |> fun states_without_false ->
        StateSet.fold
          (fun state new_states ->
            if is_reduced state
            then { new_states with all = add state new_states.all }
            else reduce_state state)
          states_without_false
          { all = empty; unmarked_by = FormulaMap.empty }
      in
      reduce new_states)
  in
  if FormulaSet.is_empty state
  then { all = empty; unmarked_by = FormulaMap.empty }
  else reduce { all = singleton state; unmarked_by = FormulaMap.empty }
;;
