DECLARE PLUGIN "analytical"

open Stdarg

let run_test_command () : unit =
  Feedback.msg_notice (Pp.str "yo\n")

(* Test command *)
VERNAC COMMAND EXTEND Test CLASSIFIED AS SIDEFF
| [ "Test" ] ->
  [ run_test_command () ]
END
