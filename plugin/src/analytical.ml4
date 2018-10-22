DECLARE PLUGIN "analytical"

open Stdarg

(*
 * Various hooks to register once we can
 *)
let print_state_add (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "ADD: %s\n" (Stateid.to_string state)))

let print_state_edit (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "EDIT: %s\n" (Stateid.to_string state)))

let print_state_exec (state : Stateid.t) : unit =
  Feedback.msg_notice
    (Pp.str (Printf.sprintf "EXEC: %s\n" (Stateid.to_string state)))

(* --- Command infrastructure --- *)

let run_test_command () : unit =
  Feedback.msg_notice (Pp.str "yo\n")

(* Test command *)
VERNAC COMMAND EXTEND Test CLASSIFIED AS SIDEFF
| [ "Test" ] ->
  [ run_test_command () ]
END
