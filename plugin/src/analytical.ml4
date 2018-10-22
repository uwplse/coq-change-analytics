DECLARE PLUGIN "analytical"

open Stdarg

(*
 * How we can print state IDs, once we have them
 *)
let unused_command (state : Stateid.t) : unit =
  Feedback.msg_notice (Pp.str (Stateid.to_string state))

let run_test_command () : unit =
  Feedback.msg_notice (Pp.str "yo\n")

(* Test command *)
VERNAC COMMAND EXTEND Test CLASSIFIED AS SIDEFF
| [ "Test" ] ->
  [ run_test_command () ]
END
