(** This libary contains the implementation of LTL formulas. *)

(** LTL formula definition. *)
type formula =
  | Bool of bool
  | Prop of string
  | Uop of uop * formula
  | Bop of formula * bop * formula

(** Unary operator *)
and uop =
  | Not
  | Next
  | Finally
  | Globally

(** Binary operator *)
and bop =
  | Or
  | And
  | Until
  | Release
  | Implies

(** {2 Helping constructor functions} *)

(** [neg phi] returns [Uop (Not, phi)] *)
val neg : formula -> formula

(** [next phi] returns [Uop (Next, phi)] *)
val next : formula -> formula

(** [finally phi] returns [Uop (Finally, phi)] *)
val finally : formula -> formula

(** [phi <|> psi] returns [Bop (phi, Or, psi)] *)
val ( <|> ) : formula -> formula -> formula

(** [phi <&> psi] returns [Bop (phi, And, psi)] *)
val ( <&> ) : formula -> formula -> formula

(** [phi <~> psi] returns [Bop (phi, Until, psi)] *)
val ( <~> ) : formula -> formula -> formula

(** [phi <^> psi] returns [Bop (phi, Release, psi)] *)
val ( <^> ) : formula -> formula -> formula

(** [phi => psi] returns [Bop (phi, Implies, psi)] *)
val ( => ) : formula -> formula -> formula

(** {2 Main logic functions} *)

(** [format fmt phi] uses [fmt] to format [phi] into its string representation. *)
val format : Format.formatter -> formula -> unit

(** [nnf phi] returns the negation normal form of [phi], i.e an equivalent LTL formula of
    [phi], where:

    - all negation appear only in front of the atomic propositions,
    - only other logical operators [∧], and [∨] can appear, and
    - only the temporal operator [X], [U], and [R] can appear. *)
val nnf : formula -> formula
