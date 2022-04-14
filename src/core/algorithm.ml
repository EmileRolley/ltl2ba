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
