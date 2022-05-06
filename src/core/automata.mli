(** Contains all the data structures and functions needs to manipulate Büchi Automata on
    transition.*)

(** {1 Data type definitions} *)

(** A set of [Ltl.formula]. *)
module FormulaSet : Set.S with type elt = Ltl.formula

(** A map with [Ltl.formula] as key. *)
module FormulaMap : Map.S with type key = Ltl.formula

(** A set of [Ltl.formula] representing a Büchi Automata state. *)
type state = FormulaSet.t

(** A set of [state]. *)
module StateSet : Set.S with type elt = state

(** Module used to describes nodes and edges for the transition graph. *)

type transition = state * FormulaSet.t * state

module TransitionSet : Set.S with type elt = transition

module TransBuchiAutomata : sig
  type automata =
    { states : StateSet.t (** States of the automata. *)
    ; transitions : TransitionSet.t (** Transitions of the automata. *)
    ; inits : StateSet.t (** Initial state. *)
    ; acceptings : TransitionSet.t FormulaMap.t (** Accepting transitions. *)
    }

  include
    Graph.Sig.I
      with type V.t =
        [ `Init of state
        | `Normal of state
        ]
       and type E.label =
        [ `Normal of FormulaSet.t
        | `Acceptant of Ltl.formula * FormulaSet.t
        ]
end

(** [Graph.Graphviz.Dot]*)
module TransBuchiAutomataDotPrinter : sig
  val fprint_graph : Stdlib.Format.formatter -> TransBuchiAutomata.t -> unit
  val output_graph : Stdlib.out_channel -> TransBuchiAutomata.t -> unit
end

(** {1 Functions} *)

(** [state_to_string ?quote ?empty state] returns the string representation of the state.

    [~empty] is the string to represent an empty state (default "∅").

    [~quote] if set to true will quote the string representation (default "false"). *)
val state_to_string : ?quote:bool -> ?empty:string -> state -> string
