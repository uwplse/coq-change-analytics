DECLARE PLUGIN "analytical"

open Goptions

(* --- Options --- *)

(*
 * When opt_debug_analytics is true, print the output of the Analytics plugin locally.
 * Otherwise (by default), send it to a remote server.
 *)
let opt_debug_analytics = ref (false)
let _ = declare_bool_option {
  optdepr = false;
  optname = "Print output of Analytics plugin locally for debugging";
  optkey = ["Debug"; "Analytics"];
  optread = (fun () -> !opt_debug_analytics);
  optwrite = (fun b -> opt_debug_analytics := b);
}

(* 
 * Lookup the debug analytics options.
 * Properly use the table and not the ref because it's probably safer.
 *)
let is_debug () : bool =
  let opts = get_tables () in
  match (OptionMap.find ["Debug"; "Analytics"] opts).opt_value with
  | BoolValue b -> b
  | _ -> false

(* --- Functionality --- *)

(*
 * Output analytics, using opt_debug_analytics to determine
 * whether to do so locally or send output to a server
 *)
let print_analytics (output : Pp.t) : unit =
  if is_debug () then
    Feedback.msg_notice output
  else
    (* TODO remove warning and send to server *)
    Feedback.msg_notice
      (Pp.seq
         [(Pp.str "Output to a server is not yet implemented. Please set the Debug Analytics option.");
          output])

(*
 * From a state ID, get the vernac AST.
 * This will change as Emilio changes the hooks.
 * For now this has a filthy hack to get the doc ID.
 *)
let vernac_of_state (state : Stateid.t) : Vernacexpr.vernac_control =
  let doc_id = ref 0 in
  let feeder = Feedback.add_feeder (fun f -> doc_id := f.doc_id; ()) in
  Feedback.feedback ~id:state Feedback.Complete;
  Feedback.del_feeder feeder;
  let doc = Stm.get_doc (!doc_id) in
  match Stm.get_ast ~doc state with
  | Some (_, v) -> v
  | _ -> failwith "state does not exist"

(*
 * Print a state ID and its AST.
 * We can change the format of this later. For now, this is a proof of concept.
 *)
let print_state (action : string) (state : Stateid.t) : Pp.t =
  Pp.seq
    [Pp.str (Printf.sprintf "%s: " action);
     Ppvernac.pr_vernac (vernac_of_state state);
     Pp.str "\n";
     Pp.str "At ID: ";
     Pp.str (Stateid.to_string state);
     Pp.str "\n"]
                     
(*
 * Hooks into the document state
 *)
let print_state_add (v : Vernacexpr.vernac_control CAst.t) (state : Stateid.t) : unit =
  print_analytics
    (Pp.seq
       [Pp.str (Printf.sprintf "ADD@%fs\n" (Unix.gettimeofday ()));
        print_state "From old state" state;
        Pp.str "Adding: ";
        Ppvernac.pr_vernac v.v;
        Pp.str "\n"])

let print_state_edit (state : Stateid.t) : unit =
  print_analytics
    (Pp.seq
       [Pp.str (Printf.sprintf "EDIT@%fs\n" (Unix.gettimeofday ()));
        print_state "Stepping back to" state])

let print_state_exec (state : Stateid.t) : unit =
  print_analytics
    (Pp.seq
       [Pp.str (Printf.sprintf "EXEC@%fs\n" (Unix.gettimeofday ()));
        print_state "Executing" state])

(*
 * Setting the hooks
 *)
let hooks : Stm.document_edit_notifiers =
  { add_hook = print_state_add ;
    edit_hook = print_state_edit ;
    exec_hook = print_state_exec ;
  }

let _ = Hook.set Stm.document_edit_hook hooks
