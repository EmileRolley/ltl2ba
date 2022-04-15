open Ltl

module FormulaSet = Set.Make (struct
  type t = Ltl.formula

  let compare = Ltl.compare
end)

module TransitionGraph = struct
  module FormulaSetLabel = struct
    type t = FormulaSet.t

    let compare = FormulaSet.compare
    let equal s s' = 0 = FormulaSet.compare s s'
    let hash = Hashtbl.hash
    let default = FormulaSet.empty
  end

  include Graph.Imperative.Digraph.ConcreteLabeled (FormulaSetLabel) (FormulaSetLabel)
end

type state = FormulaSet.t

let next state =
  FormulaSet.filter_map
    (function
      | Uop (Next, phi) -> Some phi
      | _ -> None)
    state
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
         | Uop ((Not | Next), _) ->
           (* formulas of Z are of the form: p, ¬q, or Xα *)
           true
         | _ -> false)
;;

let is_maximal phi state =
  let open FormulaSet in
  let s = remove phi state in
  if is_empty s
  then mem phi state
  else s |> exists (fun psi -> Ltl.is_subformula psi phi) |> not
;;

let red state = FormulaSet.map (fun s -> s) state
