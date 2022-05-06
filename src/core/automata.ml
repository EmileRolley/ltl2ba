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

let state_to_string ?(quote = false) ?(empty = "∅") (state : state) : string =
  if FormulaSet.is_empty state
  then empty
  else
    Printf.sprintf
      (if quote then "\" %s \"" else "%s")
      (FormulaSet.fold
         (fun f s -> s ^ (if 0 <> String.length s then ", " else "") ^ Ltl.to_string f)
         state
         "")
;;

type transition = state * FormulaSet.t * state

module TransitionSet = Set.Make (struct
  type t = transition

  let compare (s1, e, s2) (s1', e', s2') =
    if 0 <> FormulaSet.compare s1 s1'
    then FormulaSet.compare s1 s1'
    else if 0 <> FormulaSet.compare e e'
    then FormulaSet.compare e e'
    else FormulaSet.compare s2 s2'
  ;;
end)

module TransBuchiAutomata = struct
  type automata =
    { states : StateSet.t (** States of the automata. *)
    ; transitions : TransitionSet.t (** Transitions of the automata. *)
    ; inits : StateSet.t (** Initial state. *)
    ; acceptings : TransitionSet.t FormulaMap.t (** Accepting transitions. *)
    }

  include
    Graph.Imperative.Digraph.ConcreteLabeled
      (struct
        type t =
          [ `Init of state
          | `Normal of state
          ]

        let compare v v' =
          match v, v' with
          | `Normal s, `Normal s'
          | `Normal s, `Init s'
          | `Init s, `Normal s'
          | `Init s, `Init s' -> FormulaSet.compare s s'
        ;;

        let equal s s' = 0 = compare s s'
        let hash = Hashtbl.hash
      end)
      (struct
        type t =
          [ `Normal of FormulaSet.t
          | `Acceptant of Ltl.formula * FormulaSet.t
          ]

        let compare e e' =
          match e, e' with
          | `Normal s, `Normal s' -> FormulaSet.compare s s'
          | `Acceptant (phi, s), `Acceptant (phi', s') ->
            if 0 <> Ltl.compare phi phi'
            then Ltl.compare phi phi'
            else FormulaSet.compare s s'
          | `Acceptant _, `Normal _ -> -1
          | `Normal _, `Acceptant _ -> 1
        ;;

        let default = `Normal FormulaSet.empty
      end)
end

module TransBuchiAutomataDotPrinter = Graph.Graphviz.Dot (struct
  include TransBuchiAutomata

  (* TODO: calculates the sigma of phi instead of printing Σ. *)
  let edge_attributes = function
    | _, `Normal formulas, _ ->
      [ `Arrowsize 0.45; `Label (state_to_string ~empty:"Σ" formulas) ]
    | _, `Acceptant (_alpha, formulas), _ ->
      [ `Arrowsize 0.45; `Label (state_to_string ~empty:"Σ" formulas) ]
  ;;

  let default_edge_attributes _ = []
  let get_subgraph _ = None

  let vertex_attributes = function
    | `Init _ -> [ `Shape `Box ]
    | `Normal _ -> [ `Shape `Ellipse ]
  ;;

  let vertex_name = function
    | `Init s | `Normal s -> state_to_string ~quote:true s
  ;;

  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)
