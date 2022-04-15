(** This libary contains the implementation of core translating algorithm. *)
open Ltl

module FormulaSet : Set.S with type elt = Ltl.formula

module TransitionGraph : sig
  module FormulaSetLabel : sig
    type t = FormulaSet.t

    val compare : t -> t -> int
    val equal : t -> t -> bool
    val hash : t -> int
    val default : t
  end

  include Graph.Sig.G
end

type state = FormulaSet.t

module StateSet : Set.S with type elt = state

type states = StateSet.t

(** [next state] returns [{α | Xα ∈ state}] *)
val next : state -> state

(** [is_reduced state] returns true if the [state] is reduced. *)
val is_reduced : state -> bool

(** [is_maximal phi state] returns true if the formula [phi] is maximal in [state], i.e.
    [phi] is not a sub-formula of any other such formula of [state]. *)
val is_maximal : formula -> state -> bool

(** [red state] returns [Red(Y) = {Z reduced | Y ⟶{^*} Z} ] *)
val red : state -> states
