(** Contains all the data structures and functions used to manipulate Büchi Automata on
    transition.*)

(** {1 Data type definitions} *)

(** A set of {!Ltl.formula}. *)
module FormulaSet : Set.S with type elt = Ltl.formula

(** A map with {!Ltl.formula} as key. *)
module FormulaMap : Map.S with type key = Ltl.formula

(** A set of {!Ltl.formula} representing a Büchi Automata state. *)
type state = FormulaSet.t

(** A set of {!state}. *)
module StateSet : Set.S with type elt = state

(** Imperative representation of a Büchi Automata on transitions.

    It uses the
    {{:https://backtracking.github.io/ocamlgraph/ocamlgraph/Graph/Imperative/Digraph/ConcreteLabeled/index.html}
    [Graph.Imperative.Digraph.ConcreteLabeled]} functor to the implementation.

    Vertexes are labeled with {!state} where:

    - [`Init s] is the initial state labeled by [s].
    - [`Normal s] is the {i normal} state labeled by [s].

    Edges are labeled with {!FormulaSet.t} where:

    - [`Normal s] is the {i normal} transition labeled by [s].
    - [`Accept phis s] is the {i accepting} transition of all acceptance conditions F{_ α}
      with α ∈ [phis] labeled by [s]. *)
module TransBuchi : sig
  include
    Graph.Sig.I
      with type V.t =
        [ `Init of state
        | `Normal of state
        ]
       and type E.label =
        [ `Normal of FormulaSet.t
        | `Acceptant of Ltl.formula list * FormulaSet.t
        ]
end

(** Contains convenient functions to print a {!TransBuchi} in the [Dot] format

    It uses the using
    {{:https://backtracking.github.io/ocamlgraph/ocamlgraph/Graph/Graphviz/Dot/index.html}
    [Graph.Graphviz.Dot]} functor to the implementation. *)
module TransBuchiDotPrinter : sig
  (** [fprint_graph ppf ba] pretty prints the automata [ba] in the CGL language on the
      formatter [ppf].*)
  val fprint_graph : Stdlib.Format.formatter -> TransBuchi.t -> unit

  (** [output_graph oc ba] pretty prints the automata [ba] in the dot language on the
      channel [oc].*)
  val output_graph : Stdlib.out_channel -> TransBuchi.t -> unit
end

(** {1 Functions} *)

(** [state_to_string ?surround ?empty state] returns the string representation of the
    state.

    [~empty] is the string to represent an empty state (default "∅").

    [~surround] specify by whitch character the string representation is surrounded
    (default [`Empty]). *)
val state_to_string
  :  ?surround:[ `Quotes | `Braces | `Empty ]
  -> ?empty:string
  -> state
  -> string

(** [formula_map_on_sets_union m m'] returns the union of each {!StateSet.t} for each
    corresponding key of [m] and [m']. *)
val formula_map_on_sets_union
  :  StateSet.t FormulaMap.t
  -> StateSet.t FormulaMap.t
  -> StateSet.t FormulaMap.t
