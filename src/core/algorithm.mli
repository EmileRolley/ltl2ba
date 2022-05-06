(** This module contains the implementation of core translating algorithm. *)
open Ltl

(** A set of [Ltl.formula]. *)
module FormulaSet : Set.S with type elt = Ltl.formula

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

type state = FormulaSet.t

(** A set of [state]. *)
module StateSet : Set.S with type elt = state

type states = StateSet.t

(** [state_to_string ?quote ?empty state] returns the string representation of the state.

    [~empty] is the string to represent an empty state (default "∅").

    [~quote] if set to true will quote the string representation (default "false"). *)
val state_to_string : ?quote:bool -> ?empty:string -> state -> string

val states_to_string : states -> string

(** [next state] returns [{α | Xα ∈ state}] *)
val next : state -> state

(** [sigma state] returns the intersection of all p and ¬p in Z, p ∈ AP. *)
val sigma : state -> FormulaSet.t

(** [is_reduced state] returns true if the [state] is reduced. *)
val is_reduced : state -> bool

(** [is_maximal phi state] returns true if the formula [phi] is maximal in [state], i.e.
    [phi] is not a sub-formula of any other such formula of [state]. *)
val is_maximal : formula -> state -> bool

(** [red state] returns [Red(Y) = {Z reduced | Y ⟶{^*} Z} ] *)
val red : state -> states
