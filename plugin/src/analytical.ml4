DECLARE PLUGIN "analytical"

(* --- Options --- *)

(*
 * When opt_debug_analytics is true, print the output of the Analytics plugin locally.
 * Otherwise (by default), send it to a remote server.
 *)
let opt_debug_analytics = ref (false)
let _ = Goptions.declare_bool_option {
  Goptions.optdepr = false;
  Goptions.optname = "Print output of Analytics plugin locally for debugging";
  Goptions.optkey = ["Debug"; "Analytics"];
  Goptions.optread = (fun () -> !opt_debug_analytics);
  Goptions.optwrite = (fun b -> opt_debug_analytics := b);
}

(* 
 * Lookup the debug analytics options.
 * Properly use the table and not the ref because it's probably safer.
 *)
let is_debug () : bool =
  let opts = Goptions.get_tables () in
  match (Goptions.OptionMap.find ["Debug"; "Analytics"] opts).opt_value with
  | Goptions.BoolValue b -> b
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
 * Hooks into the document state
 *)
let print_state_add (v : Vernacexpr.vernac_control CAst.t) (state : Stateid.t) : unit =
  print_analytics
    (Pp.seq
       [Pp.str (Printf.sprintf "ADD@%fs: %s\n" (Unix.gettimeofday ())
                               (Stateid.to_string state)) ;
        Ppvernac.pr_vernac v.v ])

let print_state_edit (state : Stateid.t) : unit =
  print_analytics
    (Pp.str (Printf.sprintf "EDIT@%fs: %s\n" (Unix.gettimeofday ())
               (Stateid.to_string state)))

let print_state_exec (state : Stateid.t) : unit =
  print_analytics
    (Pp.str (Printf.sprintf "EXEC@%fs: %s\n" (Unix.gettimeofday ())
               (Stateid.to_string state)))

(*
 * Setting the hooks
 *)
let hooks : Stm.document_edit_notifiers =
  { add_hook = print_state_add ;
    edit_hook = print_state_edit ;
    exec_hook = print_state_exec ;
  }

let _ = Hook.set Stm.document_edit_hook hooks
