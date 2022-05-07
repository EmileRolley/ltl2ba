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

type translating_context =
  { (* Keeps track of all managed states to know when to stop iterate. *)
    mutable already_managed_states : StateSet.t
  ; (* Keeps track of all formulas used to marked edges in the intermediate graph
       representation. They represent the acceptance conditions. *)
    mutable marking_formulas : FormulaSet.t
  }

(** TODO:

    - [ ] Adds comment
    - [ ] Factorize
    - [ ] Move to Algorithm ? *)
let translate (phi : formula) : Ba.t =
  let open Al in
  let g = Ba.create () in
  let init_state = FormulaSet.singleton phi in
  let ctx =
    { already_managed_states = StateSet.empty; marking_formulas = FormulaSet.empty }
  in
  (* let already_managed_states = ref empty_red_states in *)
  let get_vertex (s : state) : Ba.vertex =
    if FormulaSet.equal init_state s then `Init s else `Normal s
  in
  let rec build (unmanaged_red_states : Al.red_states) : Al.red_states =
    (* Cli.print_log *)
    (*   "\tAlready managed states: { %s }" *)
    (*   (Al.states_to_string ctx.already_managed_states); *)
    let open StateSet in
    if subset unmanaged_red_states.all ctx.already_managed_states
    then empty_red_states
    else (
      (* Cli.print_log "\tUnmanaged state: %s" (Al.red_states_to_string
         unmanaged_red_states); *)
      let new_red_states =
        StateSet.fold
          (fun s0 red_states ->
            Cli.print_log "\tY = {%s}" (state_to_string s0);
            ctx.already_managed_states <- StateSet.add s0 ctx.already_managed_states;
            if FormulaSet.is_empty s0
            then (
              (* Adds all acceptant conditions for {} -> {}. *)
              let acceptant_formulas =
                unmanaged_red_states.marked_by
                |> FormulaMap.to_seq
                |> List.of_seq
                |> List.map (fun (phi, _) -> phi)
                |> List.append (FormulaSet.elements ctx.marking_formulas)
                |> List.sort_uniq Ltl.compare
              in
              Cli.print_log
                "\t\t- Adding acceptance transition: %s -> %s"
                (state_to_string s0)
                (state_to_string s0);
              Ba.E.create
                (get_vertex s0)
                (if 0 < List.length acceptant_formulas
                then `Acceptant (acceptant_formulas, Al.sigma s0)
                else `Normal (Al.sigma s0))
                (get_vertex s0)
              |> Ba.add_edge_e g;
              empty_red_states)
            else (
              (* Gets reduced states from [s0]. *)
              let red_states_from_s0 = Al.red s0 in
              (* Adds corresponding edges and states in the automata. *)
              if FormulaMap.is_empty red_states_from_s0.marked_by
              then
                (* All transitions are acceptant because there are no marked edges. *)
                red_states_from_s0.all
                |> StateSet.iter (fun s ->
                       Cli.print_log
                         "\t\t- Adding acceptance transition: %s -> %s"
                         (state_to_string s0)
                         (state_to_string (Al.next s));
                       let edge =
                         if FormulaSet.is_empty ctx.marking_formulas
                         then `Normal (Al.sigma s)
                         else
                           `Acceptant
                             (FormulaSet.elements ctx.marking_formulas, Al.sigma s)
                       in
                       Ba.E.create (get_vertex s0) edge (get_vertex (Al.next s))
                       |> Ba.add_edge_e g)
              else
                (* TODO: merge common acceptant transitions. *)
                red_states_from_s0.marked_by
                |> FormulaMap.iter (fun phi states ->
                       (* Adds acceptance transitions corresponding to F_[phi]. *)
                       Cli.print_log
                         "\tAdding transition for [%s] with states: %s"
                         (Ltl.to_string phi)
                         (states_to_string states);
                       StateSet.diff red_states_from_s0.all states
                       |> StateSet.iter (fun s ->
                              Cli.print_log
                                "\t\t- Adding acceptance transition for %s: %s -> %s"
                                (Ltl.to_string phi)
                                (state_to_string s0)
                                (state_to_string s);
                              Ba.E.create
                                (get_vertex s0)
                                (`Acceptant ([ phi ], Al.sigma s))
                                (get_vertex (Al.next s))
                              |> Ba.add_edge_e g);
                       states
                       |> StateSet.iter (fun s ->
                              Cli.print_log
                                "\t\t- Adding transition: %s -> %s"
                                (state_to_string s0)
                                (state_to_string s);
                              let edge =
                                Ba.E.create
                                  (get_vertex s0)
                                  (`Normal (Al.sigma s))
                                  (get_vertex (Al.next s))
                              in
                              Ba.add_edge_e g edge));
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
                    (FormulaMap.fold
                       (fun _ states red_marked_states ->
                         StateSet.fold
                           (fun s states ->
                             formula_map_on_sets_union states (Al.red s).marked_by)
                           states
                           red_marked_states)
                       red_states_from_s0.marked_by
                       red_states_from_s0.marked_by)
                  |> formula_map_on_sets_union red_states.marked_by
              }))
          unmanaged_red_states.all
          { empty_red_states with marked_by = unmanaged_red_states.marked_by }
      in
      ctx.marking_formulas
        <- FormulaSet.union
             ctx.marking_formulas
             (FormulaMap.to_seq new_red_states.marked_by
             |> Seq.map (fun (phi, _) -> phi)
             |> FormulaSet.of_seq);
      { new_red_states with
        all = filter (fun s -> not (mem s unmanaged_red_states.all)) new_red_states.all
      }
      |> build)
  in
  ignore (build { all = StateSet.singleton init_state; marked_by = FormulaMap.empty });
  g
;;

(** [parse lexbuf] returns the {!Ltl.formula} stored in the [lexbuf] if the input is
    valid, otherwise, prints an error message and returns [None].*)
let parse (lexbuf : lexbuf) : formula option =
  try Some (Parser.formula Lexer.read lexbuf) with
  | Lexer.Syntax_error msg ->
    Cli.print_err "%s" msg;
    None
  | Parser.Error ->
    Cli.print_err "Invalid formula";
    None
;;

let driver
    (formula : string) (dot_path : string option) (verbose : bool) (no_color : bool)
    : int
  =
  print_endline "--- ltl2ba v0.2.0 ---";
  Cli.verbose_flag := verbose;
  Cli.style_flag := not no_color;
  match parse (Lexing.from_string formula) with
  | Some phi ->
    Cli.print_log "Parsing formula...";
    Cli.print_ok "     φ := %s" Ltl.(to_string phi);
    Cli.print_log "Calculating NNF...";
    let phi = Ltl.nnf phi in
    Cli.print_ok "NNF(φ) := %s" Ltl.(to_string phi);
    Cli.print_log "Translating to automata...";
    let automata = translate phi in
    dot_path
    |> Option.fold ~none:() ~some:(fun path ->
           Cli.print_log "Printing automata...";
           try
             let file = open_out path in
             DotPrinter.output_graph file automata;
             Cli.print_ok "Automata successfully printed in '%s'" path
           with
           | Sys_error msg -> Cli.print_err "%s" msg);
    return_ok
  | None -> return_err
;;

let _ = Cmdliner.Cmd.v Cli.infos (Cli.ltl2ba_t driver) |> Cmdliner.Cmd.eval' |> exit
