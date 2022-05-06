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
module Label : sig
  type t = FormulaSet.t

  val compare : t -> t -> int
  val equal : t -> t -> bool
  val hash : t -> int
  val default : t
end

(** Automata represented a directed graph. *)
module TransitionGraph : Graph.Sig.I with type V.t = Label.t and type E.label = Label.t
