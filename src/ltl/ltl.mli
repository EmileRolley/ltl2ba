(** This libary contains the implementation of LTL formulas. *)

module Formula : sig
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

  val format : Format.formatter -> t -> unit
end
