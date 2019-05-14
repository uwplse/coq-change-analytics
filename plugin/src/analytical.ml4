DECLARE PLUGIN "analytical"

open Goptions
open Lwt
open Cohttp
open Cohttp_lwt_unix
open Names
open Sexplib

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
 * URI for the remote server
 *)
(*let server_uri = Uri.of_string "http://ec2-18-225-35-143.us-east-2.compute.amazonaws.com:44/coq-analytics/"*)

(*
 * Local server URI for testing
 * TODO add a debug option to switch to this
 * TODO before pushing, set to 44 and don't push start-server.sh
 *)
let server_uri = Uri.of_string "http://localhost:4444/coq-analytics/"
                                     
(*
 * Current logging buffer
 *)
let buffer = ref []

(*
 * Name of the user profile file
 *)
let profile_file = ".analytics_profile"                   

(* --- User Profile --- *)
                     
(*
 * If the user profile does not exist, ask them to register
 *
 * We start by just automatically generating a user ID.
 * Eventually, we will ask questions like user experience and type,
 * and send those to the server.
 *)
let register () =
  let register_uri = Uri.with_path server_uri "/register/" in
  let output = open_out profile_file in
  let response =
    Client.post_form [] register_uri >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  let id = Lwt_main.run response in
  let _ = Printf.fprintf output "%s\n" id in
  close_out output

(*
 * Open the user profile for reading
 *)
let open_profile () =
  try
    open_in profile_file
  with _ ->
    let _ = register () in
    try
      open_in profile_file
    with _ ->
      failwith "Cannot find user profile"

(*
 * Prompt the server for information on the user,
 * to determine whether it's necessary to ask the user more questions
 *)
let sync_profile_questions id =
  let profile_uri = Uri.with_path server_uri "/sync-profile/" in
  let response =
    let params = ("id", id) in
    Client.get (Uri.add_query_param' profile_uri params) >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  let qs = Sexp.of_string (Lwt_main.run response) in
  Base.List.t_of_sexp (Base.List.t_of_sexp Base.String.t_of_sexp) qs

(* TODO explain *)
let update_profile id answers =
  let update_uri = Uri.with_path server_uri "/update-profile/" in
  let params = [("id", [id]); ("answers", [Sexp.to_string answers])] in
  let response =
    Client.post_form params update_uri >>= fun (resp, body) ->
    let code = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in (* TODO ref. *)
  Lwt_main.run response
                 
(*
 * Update a user profile
 * TODO!!! Move to Feedback.msg_notice, and clean
 * TODO handle empty case
 * TODO!!! Also consider the input method if you do that
 * TODO!!! server-side code
 *)
let sync_profile id =
  let qs = sync_profile_questions id in
  if List.length qs = 0 then
    let _ = print_string "Welcome back!" in
    print_newline ()
  else
    let _ = print_string "Thank you for using Coq Change Analytics!" in
    let _ = print_newline () in
    let _ = print_string "We need more information from you before continuing." in
    let _ = print_newline () in
    let _ =
      print_string
        ("If you have filled this out before, then we have since " ^
           "updated these questions, and your profile is now out of date.")
    in
    let _ = print_newline () in
    let _ = print_newline () in
    let answers =
      List.map
        (fun q_and_as ->
          let _ = print_newline () in
          let _ = print_string (List.hd q_and_as) in
          let _ = print_newline () in
          let choices = List.tl q_and_as in
          let _ =
            List.iteri
              (fun i a ->
                let _ = print_int (i + 1) in
                let _ = print_string ") " in
                let _ = print_string a in
                print_newline ())
              choices
          in
          let _ = print_newline () in
          let rec get_answer choices = (* TODO refactor *)
            try
              let offset = read_int () - 1 in
              let _ = List.nth choices offset in
              offset
            with _ ->
              let _ = print_string "Invalid input, please try again" in
              let _ = print_newline () in
              get_answer choices
          in get_answer choices)
        qs
    in
    let _ = update_profile id (Base.List.sexp_of_t Base.Int.sexp_of_t answers) in
    let _ = print_string "Thank you!" in
    print_newline ()
                  
(*
 * Get the user ID from the profile, creating it if it doesn't exist
 * Prompt the user for extra information if the server says so
 *)
let user_id =
  let input = open_profile () in
  let id = input_line input in
  let _ = close_in input in
  let _ = sync_profile id in
  id
                   
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
  Printf.sprintf
    "(%s)"
    (String.concat "" (List.rev (List.map Pp.string_of_ppcmds (! buffer))))

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
          "((time %f) (id %s) (user %s) (session-module %s) (session %f)
           (Control (StmAdd () \"%s\")))"
          (Unix.gettimeofday ())
          (Stateid.to_string state)
          user_id
          session_module
          session_id
          (Pp.string_of_ppcmds (Ppvernac.pr_vernac v.v))))
    false

let print_state_edit (state : Stateid.t) : unit =
  print_analytics
    (Pp.str
       (Printf.sprintf
          "((time %f) (user %s) (session-module %s) (session %f)
           (Control (StmCancel (%s))))"
          (Unix.gettimeofday ())
          user_id
          session_module
          session_id
          (Stateid.to_string state)))
    false

let print_state_exec (state : Stateid.t) : unit =
  print_analytics
    (Pp.str
       (Printf.sprintf
          "((time %f) (user %s) (session-module %s) (session %f)
           (Control (StmObserve %s)))"
          (Unix.gettimeofday ())
          user_id
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
