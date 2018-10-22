DECLARE PLUGIN "analytical"

open Stdarg

(* Test command *)
VERNAC COMMAND EXTEND Test CLASSIFIED AS SIDEFF
| [ "Test" ] ->
  [ Feedback.msg_notice (Pp.str "yo\n") ]
END
