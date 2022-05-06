module FormulaSet = Set.Make (struct
  type t = Ltl.formula

  let compare = Ltl.compare
end)

module FormulaMap = Map.Make (struct
  type t = Ltl.formula

  let compare = Ltl.compare
end)

module StateSet = Set.Make (struct
  type t = FormulaSet.t

  let compare = FormulaSet.compare
end)

type state = FormulaSet.t

module Label = struct
  type t = FormulaSet.t

  let compare = FormulaSet.compare
  let equal s s' = 0 = FormulaSet.compare s s'
  let hash = Hashtbl.hash
  let default = FormulaSet.empty
end

module TransitionGraph = Graph.Imperative.Digraph.ConcreteLabeled (Label) (Label)
