open Lexing
open Parsing
open Core
open Ltl
open Automata
module Al = Algorithm
module G = Automata.TransBuchiAutomata
module DotPrinter = Automata.TransBuchiAutomataDotPrinter

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

(* TODO: to refactor in order to avoid using ref => using a record to keep track of
   unmanaged and managed states. *)
let translate (phi : formula) : G.t =
  let open Al in
  let g = G.create () in
  let _already_managed_states =
    ref { all = StateSet.empty; unmarked_by = FormulaMap.empty }
  in
  (* let rec build (unmanaged_states : Al.red_states) : Al.red_states = *)
  (*   Cli.print_log "\tUnmanaged states1: %s" (Al.red_states_to_string unmanaged_states); *)
  (*   Cli.print_log *)
  (*     "\tAlready managed states: %s" *)
  (*     (Al.red_states_to_string !already_managed_states); *)
  (*   let open StateSet in *)
  (*   if subset unmanaged_states.all !already_managed_states.all *)
  (*   then { all = StateSet.empty; unmarked_by = FormulaMap.empty } *)
  (*   else ( *)
  (*     Cli.print_log "\tUnmanaged state: %s" (Al.red_states_to_string unmanaged_states); *)
  (*     let new_red_states = *)
  (*       StateSet.fold *)
  (*         (fun s0 red_states -> *)
  (*           Cli.print_log "\t\tY = {%s}" (Al.state_to_string s0); *)
  (*           already_managed_states *)
  (*             := { !already_managed_states with *)
  (*                  all = StateSet.add s0 !already_managed_states.all *)
  (*                }; *)
  (*           if Al.FormulaSet.is_empty s0 *)
  (*           then ( *)
  (*             G.add_edge g s0 s0; *)
  (*             {all = empty; unmarked_by = FormulaMap.empty} *)
  (*           else ( *)
  (*             fold *)
  (*               (fun s new_red_states -> *)
  (*                 let label = Al.sigma s in *)
  (*                 let s = Al.next s in *)
  (*                 G.E.create s0 label s |> G.add_edge_e g; *)
  (*                 add s new_red_states) *)
  (*               (Al.red s0) *)
  (*               empty *)
  (*             |> union red_states)) *)
  (*         unmanaged_states.all *)
  (*         empty *)
  (*     in *)
  (*     { new_red_states with *)
  (*       all = filter (fun s -> not (mem s unmanaged_states)) new_red_states.all *)
  (*     } *)
  (*     |> build) *)
  (* in *)
  G.add_vertex g (`Init (FormulaSet.singleton phi));
  (* ignore *)
  (*   (build *)
  (*      { all = StateSet.singleton (FormulaSet.singleton phi) *)
  (*      ; unmarked_by = FormulaMap.empty *)
  (*      }); *)
  g
;;

let driver
    (formula : string) (dot_path : string option) (verbose : bool) (no_color : bool)
    : int
  =
  print_endline "--- ltl2ba v0.1.0 ---";
  Cli.verbose_flag := verbose;
  Cli.style_flag := not no_color;
  (* TODO: manage multiple formulas/input files *)
  match parse (Lexing.from_string formula) with
  | Some phi ->
    Cli.print_log "Parse:";
    Cli.print_log "\tφ := %s" Ltl.(to_string phi);
    Cli.print_log "Calculate NNF:";
    let phi = Ltl.nnf phi in
    Cli.print_log "\tφ := %s" Ltl.(to_string phi);
    Cli.print_log "Translating to automata...";
    let automata = translate phi in
    dot_path
    |> Option.fold ~none:() ~some:(fun path ->
           Cli.print_log "Printing automata in '%s'" path;
           let file = open_out path in
           DotPrinter.output_graph file automata);
    return_ok
  | None -> return_err
;;

let _ = Cmdliner.Cmd.v Cli.infos (Cli.ltl2ba_t driver) |> Cmdliner.Cmd.eval' |> exit
