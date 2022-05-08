(** This module contains the implementation of core translating algorithm. *)

open Ltl
open Automata

(** {1 Data type definitions} *)

(** Intermediate representation allowing to store reduced [states] computed by the [red]
    function.

    Each formula used as a key of the map {!marked_by} corresponds to an acceptance
    condition. More precisely, Red{_ α} = \{s ∈ S | {!marked_by} \ {!marked_by}[α] U
    {!all}\}. *)
type red_states =
  { all : StateSet.t (** Set of all reachable reduced states using only unmarked edges. *)
  ; marked_by : StateSet.t FormulaMap.t
        (** Maps a formula α to the set of only reachable reduced states by using edges
            marked with α. *)
  }

(** [empty_red_states] returns the {!red_states} with an empty [all] and an empty
    [marked_by]. *)
val empty_red_states : red_states

(** {1 Functions} *)

(** {2 Main logic functions}*)

(** [red_states_union red_states] Returns the union of all {!StateSet.t} in [red_states]. *)
val red_states_union : red_states -> StateSet.t

(** [next state] returns [{α | Xα ∈ state}] *)
val next : state -> state

(** [sigma state] returns the intersection of all p and ¬p in Z, p ∈ AP. *)
val sigma : state -> FormulaSet.t

(** [is_reduced state] returns true if the [state] is reduced. *)
val is_reduced : state -> bool

(** [is_maximal phi state] returns true if the formula [phi] is maximal in [state], i.e.
    [phi] is not a sub-formula of any other such formula of [state]. *)
val is_maximal : formula -> state -> bool

(** [red state] returns the {!red_states} corresponding the reduction of the state
    [state].

    Where:

    - {!all} is equal to \{Z reduced | [state] ⟶{^ *} Z\}
    - and the value of {!marked_by} associated to the key α equals to \{Z reduced |
      [state] ⟶{^ *} without using an edge marked by α\}*)
val red : state -> red_states

(** {2 Printing functions} *)

(** [states_to_string s] returns the string representation of all {!Automata.state} in [s]

    Each one is surrounded by [`Braces]. *)
val states_to_string : StateSet.t -> string

(** [red_states_to_string red_states] return the string representation of the
    [red_states].

    Used for debugging purpose. *)
val red_states_to_string : red_states -> string
