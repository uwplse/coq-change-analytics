DECLARE PLUGIN "analytical"

open Goptions
open Lwt
open Cohttp
open Cohttp_lwt_unix
open Names

(* --- Constants --- *)

(* 
 * Module path for the current session
 *
 * This appears to work with coqc, but not with coqtop, so for now
 * the results will only sometimes be useful.
 * See: https://github.com/coq/coq/issues/8989
 *)
let session_module = ModPath.to_string (Lib.current_mp ())

(*
 * ID for the current session
 *)
let session_id = Unix.gettimeofday ()

(*
 * URI for the server
 *)
let server_uri = Uri.of_string "http://alexsanchezstern.com:443/coq-analytics/"

(*
 * Current logging buffer
 *)
let buffer = ref []
                   
(* --- Options --- *)

(*
 * When opt_debug_analytics is true, log locally.
 * Otherwise (by default), log to a remote server.
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
 * Convert the buffer to a sequence for local debugging
 *)
let buffer_to_pp () =
  Pp.seq (List.rev (! buffer))
           
(*
 * Convert the buffer to a string to send to the server
 *)
let buffer_to_string () =
  String.concat "\n" (List.rev (List.map Pp.string_of_ppcmds (! buffer)))

(* 
 * Flush the buffer
 *)
let flush_buffer () =
  buffer := []

(*
 * Add logging info to the buffer
 *)
let add_to_buffer (output : Pp.t) : unit =
  buffer := output :: (! buffer)

(*
 * Log a message and send it to the server
 *)
let log () : unit =
  let msg = buffer_to_string () in
  let response =
    Client.post_form [("msg", [msg])] server_uri >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  ignore (Lwt_main.run response)
           
(*
 * Output analytics, using opt_debug_analytics to determine
 * whether to do so locally or send output to a server
 *)
let print_analytics (output : Pp.t) (is_exec : bool) : unit =
  let _ = add_to_buffer output in
  if is_exec then
    let _ =
      if is_debug () then
        Feedback.msg_notice (buffer_to_pp ())
      else
        log ()
    in flush_buffer ()
  else
    ()

(*
 * Hooks into the document state
 *)
let print_state_add (v : Vernacexpr.vernac_control CAst.t) (state : Stateid.t) : unit =
  print_analytics
    (Pp.str
       (Printf.sprintf
          "((time %f) (id %s) (session-module: %s) (session %f) 
           (Control (StmAdd () \"%s\")))"
          (Unix.gettimeofday ())
          (Stateid.to_string state)
          session_module
          session_id
          (Pp.string_of_ppcmds (Ppvernac.pr_vernac v.v))))
    false

let print_state_edit (state : Stateid.t) : unit =
  print_analytics
    (Pp.str
       (Printf.sprintf
          "((time %f) (session-module: %s) (session %f) 
           (Control (StmCancel (%s))))"
          (Unix.gettimeofday ())
          session_module
          session_id
          (Stateid.to_string state)))
    false

let print_state_exec (state : Stateid.t) : unit =
  print_analytics
    (Pp.str
       (Printf.sprintf
          "((time %f) (session-module: %s) (session %f) 
           (Control (StmObserve %s)))"
          (Unix.gettimeofday ())
          session_module
          session_id
          (Stateid.to_string state)))
    true

(*
 * Setting the hooks
 *)
let hooks : Stm.document_edit_notifiers =
  { add_hook = print_state_add ;
    edit_hook = print_state_edit ;
    exec_hook = print_state_exec ;
  }

let _ = Hook.set Stm.document_edit_hook hooks
