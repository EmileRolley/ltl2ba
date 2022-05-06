(** This module contains the implementation of core translating algorithm. *)

open Ltl
open Automata

(** Intermediate representation allowing to store reduced [states] computed by the [red]
    function. *)
type red_states =
  { all : StateSet.t (** Set of reachable reduced states. *)
  ; unmarked_by : StateSet.t FormulaMap.t
        (** Map of a formula α to the set of of reachable reduced states without using an
            edge marked with α. *)
  }

(** {1 Functions} *)

val red_states_to_string : red_states -> string

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
val red : state -> red_states
