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

let formula_map_on_sets_union =
  FormulaMap.union (fun _ states states' -> Some (StateSet.union states states'))
;;

let state_to_string ?(surround = `Empty) ?(empty = "∅") (state : state) : string =
  if FormulaSet.is_empty state
  then empty
  else
    Printf.sprintf
      (match surround with
      | `Quotes -> "\" %s \""
      | `Braces -> "{ %s }"
      | `Empty -> "%s")
      (FormulaSet.fold
         (fun f s -> s ^ (if 0 <> String.length s then ", " else "") ^ Ltl.to_string f)
         state
         "")
;;

module TransBuchi = struct
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
          | `Acceptant of Ltl.formula list * FormulaSet.t
          ]

        let compare e e' =
          match e, e' with
          | `Normal s, `Normal s' -> FormulaSet.compare s s'
          | `Acceptant (phis, s), `Acceptant (phis', s') ->
            if 0 <> List.compare Ltl.compare phis phis'
            then List.compare Ltl.compare phis phis'
            else FormulaSet.compare s s'
          | `Acceptant _, `Normal _ -> -1
          | `Normal _, `Acceptant _ -> 1
        ;;

        let default = `Normal FormulaSet.empty
      end)
end

module TransBuchiDotPrinter = Graph.Graphviz.Dot (struct
  include TransBuchi

  (** Default colors used to print [Headlabels] of acceptant transitions.*)
  let colors =
    [ 0x264653 (* #264653 *)
    ; 0x2a9d8f (* #2a9d8f *)
    ; 0xe9c46a (* #e9c46a *)
    ; 0xf4a261 (* #f4a261 *)
    ; 0xe76f51 (* #e76f51 *)
    ]
  ;;

  (** [pick_color phi] returns the corresponding color of the formula [phi]. *)
  let pick_color (phi : Ltl.formula) : int =
    Hashtbl.hash phi mod List.length colors |> List.nth colors
  ;;

  let default_edge_attributes _ = [ `Arrowsize 0.45 ]

  (** [edge_attributes e] returns the edge attributes for the edge [e].*)
  let (edge_attributes :
        'a * [< `Acceptant of Ltl.formula list * state | `Normal of state ] * 'b
        -> Graph.Graphviz.DotAttributes.edge list)
    = function
    | _, `Normal formulas, _ ->
      default_edge_attributes () @ [ `Label (state_to_string ~empty:"Σ" formulas) ]
    | _, `Acceptant (alphas, formulas), _ ->
      let label = alphas |> List.map Ltl.to_string |> String.concat ", " in
      default_edge_attributes ()
      @ [ `Style `Dashed
        ; `Label (state_to_string ~empty:"Σ" formulas)
        ; `Headlabel (" " ^ label ^ " ")
        ; `Labelfontcolor
            (if 1 = List.length alphas then pick_color (List.hd alphas) else 0xc72cff)
        ; `Labelfontsize 8
        ]
  ;;

  let get_subgraph _ = None

  (** [vertex_attributes v] returns the vertex attributes for the vertex [v].*)
  let (vertex_attributes :
        [< `Init of 'a | `Normal of 'b ] -> Graph.Graphviz.DotAttributes.vertex list)
    = function
    | `Init _ -> [ `Shape `Box ]
    | `Normal _ -> [ `Shape `Ellipse ]
  ;;

  (** [vertex_name v] returns the label of the vertex [v].*)
  let (vertex_name : [< `Init of state | `Normal of state ] -> string) = function
    | `Init s | `Normal s -> state_to_string ~surround:`Quotes s
  ;;

  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)
