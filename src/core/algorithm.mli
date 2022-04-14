(** This libary contains the implementation of core translating algorithm. *)

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

(** [next state] returns [{α | Xα ∈ state}] *)
val next : state -> state
