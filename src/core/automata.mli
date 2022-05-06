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

(** Imperative representation of a Büchi Automata on transitions. *)
module TransBuchi : sig
  type automata_t =
    { mutable states : StateSet.t (** States of the automata. *)
    ; mutable transitions : TransitionSet.t (** Transitions of the automata. *)
    ; mutable inits : StateSet.t (** Initial state. *)
    ; mutable acceptings : TransitionSet.t FormulaMap.t (** Accepting transitions. *)
    }

  val automata : automata_t

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
module TransBuchiDotPrinter : sig
  val fprint_graph : Stdlib.Format.formatter -> TransBuchi.t -> unit
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
