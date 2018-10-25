DECLARE PLUGIN "analytical"

(*
 * Hooks into the document state
 *)
let print_state_add (v : Vernacexpr.vernac_control CAst.t) (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "ADD: %s\n" (Stateid.to_string state)))

let print_state_edit (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "EDIT: %s\n" (Stateid.to_string state)))

let print_state_exec (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "EXEC: %s\n" (Stateid.to_string state)))

(*
 * Setting the hooks
 *)
let hooks : Stm.document_edit_notifiers =
  { add_hook = print_state_add ;
    edit_hook = print_state_edit ;
    exec_hook = print_state_exec ;
  }

let _ = Hook.set Stm.document_edit_hook hooks
