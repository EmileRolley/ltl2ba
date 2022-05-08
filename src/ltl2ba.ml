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

(** Convenient functions for logging addition of a transition. *)

let log_adding_acceptance_transition
    (s0 : state) ((acceptant_formulas, sigmas) : formula list * FormulaSet.t) (s1 : state)
  =
  Cli.print_log
    "\t\t- Adding acceptance transition for (%s): %s -- %s -> %s"
    (acceptant_formulas |> List.map Ltl.to_string |> String.concat ",")
    (state_to_string s0)
    (state_to_string ~empty:"Σ" sigmas)
    (state_to_string s1)
;;

let log_adding_transition s0 sigmas s1 =
  Cli.print_log
    "\t\t- Adding transition: %s -- %s -> %s"
    (state_to_string s0)
    (state_to_string ~empty:"Σ" sigmas)
    (state_to_string s1)
;;

type translating_context =
  { (* Initial state. *)
    init_state : state
  ; (* Partial application of {!Al.sigma} with atomic propositions inferred from
       {!init_state}.*)
    get_sigma : state -> FormulaSet.t
  ; (* Büchi automata. *)
    ba : Ba.t
  ; (* Keeps track of current unmanaged reduced states. *)
    unmanaged_red_states : Al.red_states
  ; (* Keeps track of all managed states to know when to stop iterate. *)
    already_managed_states : StateSet.t
  ; (* Keeps track of all formulas used to marked edges in the intermediate graph
       representation. They represent the acceptance conditions. *)
    marking_formulas : FormulaSet.t
  }

(** [add_states_from s0 (ctx, red_states)] Updates the current translating context [ctx]
    by computing and adding all new states from [s0] in [ctx.ba].*)
let add_states_from (s0 : state) ((ctx, red_states) : translating_context * Al.red_states)
    : translating_context * Al.red_states
  =
  let open Al in
  let get_vertex (s : state) : Ba.vertex =
    if FormulaSet.equal ctx.init_state s then `Init s else `Normal s
  in
  let add_acceptant_trans
      (ctx : translating_context) (s : state) (acceptant_formulas : formula list)
    =
    let v0 = get_vertex s0
    and sigma = ctx.get_sigma s
    and v1 = get_vertex (Al.next s) in
    let acceptant_formulas, sigma =
      (* Merges transitions if possible. *)
      Ba.find_all_edges ctx.ba v0 v1
      |> List.fold_left
           (fun (fs, sigs) e ->
             match Ba.E.label e with
             | `Acceptant (f, s) when f = fs ->
               (* (v0 - Σ ->φ v1) and (v0 - Σ' ->φ v1) is equivalent to (v0 - Σ U Σ' ->φ
                  v1 *)
               Ba.remove_edge_e ctx.ba e;
               ( fs
               , if FormulaSet.is_empty s
                 then (* [s] is empty means that Σ = AP. *)
                   s
                 else FormulaSet.union s sigs )
             | `Acceptant (f, s) when s = sigs ->
               (* (v0 - Σ ->φ v1) and (v0 - Σ ->φ' v1) is equivalent to (v0 - Σ ->(φ, φ')
                  v1) v1 *)
               Ba.remove_edge_e ctx.ba e;
               f @ fs, sigs
             | `Normal s when s = sigma ->
               (* (v0 - Σ -> v1) and (v0 - Σ ->φ v1) is equivalent to (v0 - Σ ->φ v1) *)
               Ba.remove_edge_e ctx.ba e;
               fs, sigs
             | _ -> fs, sigs)
           (acceptant_formulas, sigma)
    in
    log_adding_acceptance_transition s0 (acceptant_formulas, sigma) (Al.next s);
    if 0 < List.length acceptant_formulas
    then
      Ba.E.create v0 (`Acceptant (acceptant_formulas, sigma)) v1 |> Ba.add_edge_e ctx.ba
  in
  let add_normal_trans (ctx : translating_context) (s : state) =
    let v0 = get_vertex s0
    and sigma = ctx.get_sigma s
    and v1 = get_vertex (Al.next s) in
    if not
       @@ (Ba.find_all_edges ctx.ba v0 v1
          |> List.exists (fun e ->
                 match Ba.E.label e with
                 | `Acceptant (_, s) ->
                   (* If there is already an acceptance transition, no needs to add the
                      noraml one. *)
                   s = sigma
                 | _ -> false))
    then (
      log_adding_transition s0 sigma (Al.next s);
      Ba.add_edge_e ctx.ba (Ba.E.create v0 (`Normal sigma) v1))
  in
  Cli.print_log "\tY = {%s}" (state_to_string s0);
  let ctx =
    { ctx with already_managed_states = StateSet.add s0 ctx.already_managed_states }
  in
  if FormulaSet.is_empty s0
  then (
    (* Adds all acceptant conditions for (s0 -> {}). *)
    ctx.unmanaged_red_states.marked_by
    |> FormulaMap.to_seq
    |> List.of_seq
    |> List.map (fun (phi, _) -> phi)
    |> List.append (FormulaSet.elements ctx.marking_formulas)
    |> List.sort_uniq Ltl.compare
    |> add_acceptant_trans ctx s0;
    ctx, empty_red_states)
  else (
    (* Gets reduced states from [s0]. *)
    let red_states_from_s0 = Al.red s0 in
    (* Adds corresponding edges and states in the automata. *)
    if FormulaMap.is_empty red_states_from_s0.marked_by
    then
      (* All transitions are acceptant because there are no marked edges. *)
      red_states_from_s0.all
      |> StateSet.iter (fun s ->
             let edge =
               if FormulaSet.is_empty ctx.marking_formulas
               then (
                 let sigma = ctx.get_sigma s in
                 log_adding_transition s0 sigma (Al.next s);
                 `Normal sigma)
               else (
                 let label = FormulaSet.elements ctx.marking_formulas, ctx.get_sigma s in
                 log_adding_acceptance_transition s0 label (Al.next s);
                 `Acceptant label)
             in
             Ba.E.create (get_vertex s0) edge (get_vertex (Al.next s))
             |> Ba.add_edge_e ctx.ba)
    else
      red_states_from_s0.marked_by
      |> FormulaMap.iter (fun phi states ->
             (* Adds acceptance transitions corresponding to F_[phi].

                Red{_ α} = {s ∈ S | ({!marked_by} U {!all}) \ {!marked_by}[α] }. *)
             StateSet.diff (red_states_union red_states_from_s0) states
             |> StateSet.iter (fun s -> add_acceptant_trans ctx s [ phi ]);
             StateSet.iter (add_normal_trans ctx) states);
    ( ctx
    , { all =
          StateSet.empty
          |> StateSet.fold
               (fun s next_red_state -> StateSet.add (next s) next_red_state)
               red_states_from_s0.all
          |> StateSet.union red_states.all
      ; marked_by =
          FormulaMap.map
            (fun states ->
              StateSet.fold
                (fun s next_red_state -> StateSet.add (next s) next_red_state)
                states
                StateSet.empty)
            (FormulaMap.fold
               (fun _ states red_marked_states ->
                 StateSet.fold
                   (fun s states -> formula_map_on_sets_union states (Al.red s).marked_by)
                   states
                   red_marked_states)
               red_states_from_s0.marked_by
               red_states_from_s0.marked_by)
          |> formula_map_on_sets_union red_states.marked_by
      } ))
;;

let translate (phi : formula) : Ba.t =
  let open Al in
  let init_state = FormulaSet.singleton phi in
  let ctx =
    { init_state
    ; get_sigma = sigma
    ; ba = Ba.create ()
    ; unmanaged_red_states = { empty_red_states with all = StateSet.singleton init_state }
    ; already_managed_states = StateSet.empty
    ; marking_formulas = FormulaSet.empty
    }
  in
  let rec build (ctx : translating_context) : translating_context =
    let open StateSet in
    if subset ctx.unmanaged_red_states.all ctx.already_managed_states
    then ctx
    else (
      let ctx, new_red_states =
        (* Adds new states to the [ctx.ba]. *)
        StateSet.fold
          add_states_from
          (red_states_union ctx.unmanaged_red_states)
          (ctx, ctx.unmanaged_red_states)
      in
      build
        { ctx with
          unmanaged_red_states =
            { new_red_states with
              all =
                filter
                  (fun s -> not (mem s ctx.unmanaged_red_states.all))
                  new_red_states.all
            }
        ; marking_formulas =
            FormulaSet.union
              ctx.marking_formulas
              (FormulaMap.to_seq new_red_states.marked_by
              |> Seq.map (fun (phi, _) -> phi)
              |> FormulaSet.of_seq)
        })
  in
  ignore (build ctx);
  ctx.ba
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
