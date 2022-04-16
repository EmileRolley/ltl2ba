open Lexing
open Parsing
open Ltl
open Core
module Al = Algorithm
module G = Algorithm.TransitionGraph

module Dot = Graph.Graphviz.Dot (struct
  include G

  (* TODO: calculates the sigma of phi instead of printing Σ. *)
  let edge_attributes (e : E.t) =
    [ `Arrowsize 0.45; `Label (E.label e |> Al.state_to_string ~empty:"Σ") ]
  ;;

  let default_edge_attributes _ = []
  let get_subgraph _ = None
  let vertex_attributes _ = [ `Shape `Ellipse ]
  let vertex_name v = Al.state_to_string ~quote:true v
  let default_vertex_attributes _ = []
  let graph_attributes _ = []
end)

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

let translate (phi : formula) : Al.TransitionGraph.t =
  let g = G.create () in
  let rec build (unmanaged_states : Al.states) : Al.states =
    let open Al.StateSet in
    if is_empty unmanaged_states
    then empty
    else (
      Cli.print_log "\tUnmanaged state: %s" (Al.states_to_string unmanaged_states);
      fold
        (fun s0 states ->
          Cli.print_log "\t\tY = {%s}" (Al.state_to_string s0);
          if Al.FormulaSet.is_empty s0
          then (
            G.add_edge g s0 s0;
            empty)
          else
            fold
              (fun s new_states ->
                let label = Al.sigma s in
                let s = Al.next s in
                G.E.create s0 label s |> G.add_edge_e g;
                add s new_states)
              (Al.red s0)
              empty
            |> union states)
        unmanaged_states
        empty
      |> filter (fun s -> not (mem s unmanaged_states))
      |> build)
  in
  ignore Al.(build (StateSet.singleton (FormulaSet.singleton phi)));
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
           Dot.output_graph file automata);
    return_ok
  | None -> return_err
;;

let _ = Cmdliner.Cmd.v Cli.infos (Cli.ltl2ba_t driver) |> Cmdliner.Cmd.eval' |> exit
