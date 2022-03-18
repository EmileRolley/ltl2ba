(** Prints debug information *)
let debug_flag = ref false

open Cmdliner

let debug = Arg.(value & flag & info [ "debug"; "d" ] ~doc:"Prints debug information")

let formula =
  Arg.(
    value
    & opt (some string) None
    & info [ "formula"; "f" ] ~doc:"Input LTL formula to compile")
;;

let ltl2ba_t f = Term.(const f $ formula $ debug)
let infos = Cmd.info "ltl2ba"
