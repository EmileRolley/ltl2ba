open Lexing
open Parsing

let return_ok = 0
let return_err = 1

let parse (lexbuf : lexbuf) : Ast.formula option =
  try Some (Parser.formula Lexer.read lexbuf) with
  | Lexer.Syntax_error msg ->
    Printf.printf "[ERROR] %s\n" msg;
    None
  | Parser.Error ->
    Printf.printf "[ERROR] parser error\n";
    None
;;

let driver (formula : string option) (_debug : bool) : int =
  print_endline "Hello, World!";
  formula
  |> Option.fold ~none:return_ok ~some:(fun formula ->
         match parse (Lexing.from_string formula) with
         | Some f ->
           f |> Ast.formula_to_string |> print_endline;
           return_ok
         | None -> return_err)
;;

let _ = Cmdliner.Cmd.v Cli.infos (Cli.ltl2ba_t driver) |> Cmdliner.Cmd.eval' |> exit
