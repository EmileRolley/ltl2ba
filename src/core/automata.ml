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

module TransBuchi = struct
  type automata_t =
    { mutable states : StateSet.t
    ; mutable transitions : TransitionSet.t
    ; mutable inits : StateSet.t
    ; mutable acceptings : TransitionSet.t FormulaMap.t
    }

  let automata =
    { states = StateSet.empty
    ; transitions = TransitionSet.empty
    ; inits = StateSet.empty
    ; acceptings = FormulaMap.empty
    }
  ;;

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

  (** TODO: add_edges + print_automata*)
  let add_vertex g v =
    (* Adds to [TransBuchiAutomata.automata]. *)
    (match v with
    | `Init s ->
      automata.inits <- StateSet.add s automata.inits;
      automata.states <- StateSet.add s automata.states
    | `Normal s -> automata.states <- StateSet.add s automata.states);
    (* Adds to [TransBuchiAutomata.t] (function implemented by the [Graph] module. *)
    add_vertex g v
  ;;
end

module TransBuchiDotPrinter = Graph.Graphviz.Dot (struct
  include TransBuchi

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
