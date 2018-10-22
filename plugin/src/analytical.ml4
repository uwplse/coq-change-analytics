DECLARE PLUGIN "analytical"

open Stdarg

(* Test command *)
VERNAC COMMAND EXTEND Test CLASSIFIED AS SIDEFF
| [ "Test" ] ->
  [ Printf.printf "%s\n\n" "yo" ]
END
