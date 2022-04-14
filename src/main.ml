open Lexing
open Parsing
open Ltl

let return_ok = 0
let return_err = 1

let parse (lexbuf : lexbuf) : formula option =
  try Some (Parser.formula Lexer.read lexbuf) with
  | Lexer.Syntax_error msg ->
    Printf.printf "[ERROR] %s\n" msg;
    None
  | Parser.Error ->
    Printf.printf "[ERROR] parser error\n";
    None
;;

let driver (formula : string option) (_debug : bool) : int =
  print_endline "--- ltl2ba v0.1.0 ---\n";
  formula
  |> Option.fold ~none:return_ok ~some:(fun formula ->
         match parse (Lexing.from_string formula) with
         | Some phi ->
           let phi_str = Ltl.to_string phi
           and nnf_phi_str = phi |> Ltl.nnf |> Ltl.to_string in
           Printf.printf "     φ := %s" phi_str;
           Printf.printf "\nnnf(φ) := %s\n" nnf_phi_str;
           return_ok
         | None -> return_err)
;;

let _ = Cmdliner.Cmd.v Cli.infos (Cli.ltl2ba_t driver) |> Cmdliner.Cmd.eval' |> exit
