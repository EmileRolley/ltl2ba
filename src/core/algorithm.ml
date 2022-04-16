open Ltl

module FormulaSet = Set.Make (struct
  type t = Ltl.formula

  let compare = Ltl.compare
end)

module StateSet = Set.Make (struct
  type t = FormulaSet.t

  let compare = FormulaSet.compare
end)

module Label = struct
  type t = FormulaSet.t

  let compare = FormulaSet.compare
  let equal s s' = 0 = FormulaSet.compare s s'
  let hash = Hashtbl.hash
  let default = FormulaSet.empty
end

module TransitionGraph = Graph.Imperative.Digraph.ConcreteLabeled (Label) (Label)

type state = FormulaSet.t

let state_to_string ?(quote = false) ?(empty = "∅") (state : state) : string =
  if FormulaSet.is_empty state
  then empty
  else
    Printf.sprintf
      (if quote then "\" %s \"" else "%s")
      (FormulaSet.fold
         (fun f s -> s ^ (if 0 <> String.length s then ", " else "") ^ to_string f)
         state
         "")
;;

type states = StateSet.t

(* TODO: could factorized with [state_to_string]. *)
let states_to_string (states : states) : string =
  Printf.sprintf
    "{ %s }"
    (StateSet.fold
       (fun f s -> s ^ (if 0 <> String.length s then ", " else "") ^ state_to_string f)
       states
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
  let s = remove phi state in
  if is_empty s
  then mem phi state
  else
    s
    |> exists (fun psi ->
           Ltl.(
             is_subformula psi phi
             || (* It's assumes that AP are one letter long, a structural comparison
                   should be implemented instead.*)
             -1 = String.compare (to_string psi) (to_string phi)))
    |> not
;;

let red state =
  let open StateSet in
  (* Reduces first maximal not reduced subset of [tmp_state] *)
  (* FIXME: infinite loop for formulas with G and R. *)
  let reduce_state (tmp_state : state) : states =
    Printf.printf "\tReducing state: %s\n" (state_to_string tmp_state);
    (* Finds first maximal not reduced subset of [tmp_state], if exists, otherwise,
       returns simply the first formula of [tmp_state]. *)
    tmp_state
    |> FormulaSet.filter (fun phi -> not (formula_is_reduced phi))
    |> FormulaSet.find_last_opt (fun phi -> is_maximal phi tmp_state)
    |> Option.fold
       (* FIXME: what is supposed to be done when there is no maximal unreduced formulas
          in [tmp_state]? *)
         ~none:(singleton tmp_state)
         ~some:(fun alpha ->
           let tmp_state = FormulaSet.remove alpha tmp_state in
           match alpha with
           | Bop (a1, Or, a2) ->
             (* If α = α1 ∨ α2, Y ⟶ Z ∪ {α1} and Y ⟶ Z ∪ {α2} *)
             empty
             |> add FormulaSet.(add a1 tmp_state)
             |> add FormulaSet.(add a2 tmp_state)
           | Bop (a1, And, a2) ->
             (* If α = α1 ∧ α2, Y ⟶ Z ∪ {α1, α2} *)
             empty |> add FormulaSet.(tmp_state |> add a1 |> add a2)
           | Bop (a1, Release, a2) ->
             (* If α = α1 R α2, Y ⟶ Z ∪ {α1, α2} and Y ⟶ Z ∪ {Xα, α2} *)
             empty
             |> add FormulaSet.(tmp_state |> add a1 |> add a2)
             |> add FormulaSet.(tmp_state |> add (Ltl.next alpha) |> add a2)
           | Bop (a1, Until, a2) ->
             (* If α = α1 U α2, Y ⟶ Z ∪ {α2} and Y ⟶α Z ∪ {Xα, α1} *)
             empty
             |> add FormulaSet.(add a2 tmp_state)
             |> add FormulaSet.(tmp_state |> add (Ltl.next alpha) |> add a1)
           | _ ->
             Ltl.to_string alpha |> Printf.printf "%s\n";
             failwith
               " should never be reached, as [alpha] is the maximal not reduced subset \
                of [state]\n")
  in
  (* Reduces the state in [states] until all states are reduced, meaning that [states]
     contains all the leafs of the temporary oriented graph built from [state] *)
  let rec reduce (states : states) : states =
    if for_all is_reduced states
    then states
    else (
      let new_states =
        StateSet.fold
          (fun state new_states -> union new_states (reduce_state state))
          states
          empty
      in
      if StateSet.equal new_states states then states else reduce new_states)
  in
  if FormulaSet.is_empty state then empty else reduce (singleton state)
;;
