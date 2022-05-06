open Lexing
open Parsing
open Core
open Ltl
open Automata
module Al = Algorithm
module Ba = Automata.TransBuchi
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
let translate (phi : formula) : Ba.t =
  let open Al in
  let g = Ba.create () in
  let init_state = FormulaSet.singleton phi in
  let already_managed_states = ref empty_red_states in
  let get_vertex (s : state) : Ba.vertex =
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
              unmanaged_states.marked_by
              |> FormulaMap.iter (fun phi states ->
                     if not (StateSet.mem s0 states)
                     then
                       Ba.E.create
                         (get_vertex s0)
                         (`Acceptant (phi, Al.sigma s0))
                         (get_vertex s0)
                       |> Ba.add_edge_e g);
              empty_red_states)
            else (
              (* Gets reduced states from [s0]. *)
              let red_states_from_s0 = Al.red s0 in
              Cli.print_log
                "\t Al.red [%s]: %s"
                (state_to_string s0)
                (red_states_to_string red_states_from_s0);
              (* Adds corresponding edges and states in the automata. *)
              if FormulaMap.is_empty red_states_from_s0.marked_by
              then
                red_states_from_s0.all
                |> StateSet.iter (fun s ->
                       Ba.E.create
                         (get_vertex s0)
                         (`Normal (Al.sigma s))
                         (get_vertex (Al.next s))
                       |> Ba.add_edge_e g)
              else
                red_states_from_s0.marked_by
                |> FormulaMap.iter (fun phi states ->
                       (* Adds acceptance transitions corresponding to F_[phi]. *)
                       states
                       |> StateSet.iter (fun s ->
                              Ba.E.create
                                (get_vertex s0)
                                (`Normal (Al.sigma s))
                                (get_vertex (Al.next s))
                              |> Ba.add_edge_e g);
                       StateSet.diff red_states_from_s0.all states
                       |> StateSet.iter (fun s ->
                              Ba.E.create
                                (get_vertex s0)
                                (`Acceptant (phi, Al.sigma s))
                                (get_vertex (Al.next s))
                              |> Ba.add_edge_e g));
              { all =
                  fold
                    (fun s next_red_state -> add (next s) next_red_state)
                    red_states_from_s0.all
                    StateSet.empty
                  |> union red_states.all
              ; marked_by =
                  FormulaMap.map
                    (fun states ->
                      fold
                        (fun s next_red_state -> add (next s) next_red_state)
                        states
                        StateSet.empty)
                    red_states_from_s0.marked_by
                  |> FormulaMap.union
                       (fun _ states states' -> Some (union states states'))
                       red_states.marked_by
              }))
          unmanaged_states.all
          empty_red_states
      in
      { new_red_states with
        all = filter (fun s -> not (mem s unmanaged_states.all)) new_red_states.all
      }
      |> build)
  in
  ignore (build { all = StateSet.singleton init_state; marked_by = FormulaMap.empty });
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
