open Lexing
open Parsing
open Core
open Ltl
open Automata
module Al = Algorithm
module G = Automata.TransBuchi
module DotPrinter = Automata.TransBuchiDotPrinter

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
  let init_state = FormulaSet.singleton phi in
  let already_managed_states = ref empty_red_states in
  let get_vertex (s : state) : G.vertex =
    if FormulaSet.equal init_state s then `Init s else `Normal s
  in
  let rec build (unmanaged_states : Al.red_states) : Al.red_states =
    Cli.print_log "\tUnmanaged states1: %s" (Al.red_states_to_string unmanaged_states);
    Cli.print_log
      "\tAlready managed states: %s"
      (Al.red_states_to_string !already_managed_states);
    let open StateSet in
    if subset unmanaged_states.all !already_managed_states.all
    then empty_red_states
    else (
      Cli.print_log "\tUnmanaged state: %s" (Al.red_states_to_string unmanaged_states);
      let new_red_states =
        StateSet.fold
          (fun s0 red_states ->
            Cli.print_log "\t\tY = {%s}" (state_to_string s0);
            already_managed_states
              := { !already_managed_states with
                   all = StateSet.add s0 !already_managed_states.all
                 };
            if FormulaSet.is_empty s0
            then (
              G.add_edge g (get_vertex s0) (get_vertex s0);
              empty_red_states)
            else (
              let red_states_from_s0 = Al.red s0 in
              { red_states with
                all =
                  (fold
                     (fun s new_red_states ->
                       let label = Al.sigma s in
                       let s = Al.next s in
                       G.E.create (get_vertex s0) (`Normal label) (get_vertex s)
                       |> G.add_edge_e g;
                       { new_red_states with all = add s new_red_states.all })
                     red_states_from_s0.all
                     empty_red_states)
                    .all
              }))
          unmanaged_states.all
          empty_red_states
      in
      { new_red_states with
        all = filter (fun s -> not (mem s unmanaged_states.all)) new_red_states.all
      }
      |> build)
  in
  ignore (build { all = StateSet.singleton init_state; unmarked_by = FormulaMap.empty });
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
