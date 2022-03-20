(** This libary contains the implementation of LTL formulas. *)

module Formula : sig
  (** LTL formula definition. *)
  type t =
    | Bool of bool
    | Prop of string
    | Uop of uop * t
    | Bop of t * bop * t

  and uop =
    | Not
    | Next

  and bop =
    | Or
    | And
    | Until
    | Release

  (** {2 Helping constructor functions} *)

  (** [neg phi] returns [Uop (Not, phi)] *)
  val neg : t -> t

  (** [next phi] returns [Uop (Next, phi)] *)
  val next : t -> t

  (** [phi <|> psi] returns [Bop (phi, Or, psi)] *)
  val ( <|> ) : t -> t -> t

  (** [phi <&> psi] returns [Bop (phi, And, psi)] *)
  val ( <&> ) : t -> t -> t

  (** [phi <~> psi] returns [Bop (phi, Until, psi)] *)
  val ( <~> ) : t -> t -> t

  (** [phi <^> psi] returns [Bop (phi, Release, psi)] *)
  val ( <^> ) : t -> t -> t

  (** {2 Main logic functions} *)

  (** [format fmt phi] uses [fmt] to format [phi] into its string representation. *)
  val format : Format.formatter -> t -> unit

  (** [nnf phi] returns the negation normal form of [phi]. *)
  val nnf : t -> t
end
