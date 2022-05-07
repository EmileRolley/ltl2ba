open Cmdliner

let verbose = Arg.(value & flag & info [ "verbose"; "v" ] ~doc:"Prints information")
let no_color = Arg.(value & flag & info [ "no-color"; "c" ] ~doc:"Disables colors")

let dot_path =
  Arg.(
    value
    & opt (some string) None
    & info [ "dot-path"; "d" ] ~doc:"Path to writes automata DOT file into")
;;

let formula =
  Arg.(required & pos 0 (some string) None & info [] ~doc:"LTL formula to compile")
;;

let ltl2ba_t f = Term.(const f $ formula $ dot_path $ verbose $ no_color)
let infos = Cmd.info "ltl2ba"
let verbose_flag = ref false
let style_flag = ref true

let with_style (styles : ANSITerminal.style list) (str : ('a, unit, string) format)
    : string
  =
  if !style_flag then ANSITerminal.sprintf styles str else Printf.sprintf str
;;

let with_style' (styles : ANSITerminal.style list) (str : string) : string =
  if !style_flag then ANSITerminal.sprintf styles "%s" str else Printf.sprintf "%s" str
;;

let log_marker () = with_style ANSITerminal.[ Bold; blue ] "[LOG] "

let print_log (fmt : ('a, out_channel, unit) format) =
  if !verbose_flag
  then Printf.printf ("%s" ^^ fmt ^^ "\n%!") (log_marker ())
  else Printf.ifprintf stdout fmt
;;

let ok_marker () = with_style ANSITerminal.[ Bold; green ] "[OK] "

let print_ok (fmt : ('a, out_channel, unit) format) =
  Printf.printf ("%s" ^^ fmt ^^ "\n%!") (ok_marker ())
;;

let err_marker () = with_style ANSITerminal.[ Bold; red ] "[ERR] "

let print_err (fmt : ('a, out_channel, unit) format) =
  Printf.eprintf ("%s" ^^ fmt ^^ "\n%!") (err_marker ())
;;
