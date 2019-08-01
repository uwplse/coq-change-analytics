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
 *
 * To debug, set to localhost with desired port instead, and update
 * start-server.sh to use the desired port
 *)
let server_uri = Uri.of_string "http://ec2-18-225-35-143.us-east-2.compute.amazonaws.com:44/coq-analytics/"
                                     
(*
 * Current logging buffer
 *)
let buffer = ref []

(*
 * The last time the logs were sent to the server (seconds accuracy)
 *)
let last_sent = ref (Unix.time ())

(*
 * The minimum frequency with which to send the logs to the server, in seconds
 * The exception is that when a module closes, we always send
 *)
let send_frequency = 5

(*
 * Name of the user profile file
 *)
let profile_file =
  Printf.sprintf "%s/%s" (Sys.getenv "HOME") ".analytics_profile"

(*
 * Name of a file to log to temporarily, when the network is down
 *)
let temp_log_file =
  Printf.sprintf "%s/%s" (Sys.getenv "HOME") ".analytics_log"
                 
(* --- Errors and warnings --- *)

let err_no_network =
  "An error occurred. Please check your network connection. " ^
  "If your network connection is working, and you continue to " ^
  "encounter this error, please report a bug in " ^
  "the uwplse/coq-change-analytics Github project."

let err_bad_user =
  "An Analytics profile for the user with your ID does not exist. " ^
  "So that we can help you fix this issue, please report this in " ^
  "the uwplse/coq-change-analytics Github project."

let warn_no_network =
  CWarnings.create ~name:"analytics_no_network" ~category:"analytics"
                   (fun _ -> Pp.strbrk err_no_network)
                            
(* --- User Profile --- *)

(*
 * Call the server to register a profile, and return the identifier.
 * Don't yet write it to file.
 *)
let try_register () : string =
  let register_uri = Uri.with_path server_uri "/register/" in
  try
    let response =
      Client.post_form ~params:[] register_uri >>= fun (resp, body) ->
      let _ = resp |> Response.status |> Code.code_of_status in
      body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
    Lwt_main.run response
  with _ ->
    ""

(*
 * Check if the identifier is valid.
 * Note that this does not check if the server is aware of the identifier.
 * This just checks to make sure the format is correct.
 *)
let id_is_valid id : bool =
  match int_of_string_opt id with
  | Some _ ->
     true
  | _ ->
     false
               
(*
 * If the user profile does not exist, ask them to register
 *
 * We start by just automatically generating a user ID.
 * Eventually, we will ask questions like user experience and type,
 * and send those to the server.
 *)
let register () : unit =
  print_string
    ("Registering a profile with the Analytics server. " ^
     "You will need a network connection.");
  print_newline ();
  let id = try_register () in
  if id_is_valid id then
    let output = open_out profile_file in
    Printf.fprintf output "%s\n" id;
    close_out output
  else
    let _ =
      if Sys.file_exists profile_file then
        Sys.remove profile_file
      else
        ()
    in CErrors.user_err (Pp.str err_no_network)

(*
 * Open the user profile for reading
 *)
let open_profile () =
  try
    open_in profile_file
  with _ ->
    register ();
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
    let _ = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  let qs_str =
    try
      Lwt_main.run response
    with _ ->
      warn_no_network ();
      "()"
  in
  try
    let qs = Sexp.of_string qs_str in
    Base.List.t_of_sexp (Base.List.t_of_sexp Base.String.t_of_sexp) qs
  with _ ->
    CErrors.user_err (Pp.str err_bad_user)

(*
 * If the user must answer more questions,
 * send those answers to the server to update the user's profile
 *)
let update_profile id answers =
  let update_uri = Uri.with_path server_uri "/update-profile/" in
  let params = [("id", [id]); ("answers", [Sexp.to_string answers])] in
  let response =
    Client.post_form ~params:params update_uri >>= fun (resp, body) ->
    let _ = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  try
    ignore (Lwt_main.run response)
  with _ ->
    warn_no_network ()
    
               
(*
 * Get the answer to a profile question from user input
 * Return an integer that marks the offset of the answer to that question
 *)
let get_answer choices =
  let read_answer () =
    let offset = read_int () - 1 in
    let _ = List.nth choices offset in
    offset
  in
  try
    read_answer ()
  with _ ->
    print_string "Invalid input, please try again.";
    print_newline (); print_newline ();
    print_string
      ("Note: The question answering process is not supported outside of the " ^
       "command line. If you are seeing this message within an IDE, please " ^
       "type another invalid input to exit the build process. Then, rebuild " ^
       "the plugin via command line to update your answers to the " ^
       "registration questions. You may then resume normal development.");
    print_newline (); print_newline ();
    try
      read_answer ()
    with _ ->
      print_string "Exiting Coq Change Analytics.";
      failwith "User exited"   

(* 
 * Ask a user a question for their profile
 *)
let ask_question q_and_as =
  print_newline ();  print_string (List.hd q_and_as); print_newline ();
  let choices = List.tl q_and_as in
  List.iteri
    (fun i a ->
      let opt = i + 1 in
      print_int opt; print_string ") "; print_string a; print_newline ())
    choices;
  print_newline ();
  get_answer choices
  
(*
 * Ask a user questions when their profile is not up to date
 * Return their answers as sexp
 *)
let ask_profile_questions qs =
  print_string "Thank you for using Coq Change Analytics!"; print_newline ();
  print_string "We need more information before continuing."; print_newline ();
  print_newline ();
  print_string
    ("If you have filled this out before, then we have since " ^
       "updated these questions, and your profile is now out of date.");
  print_newline (); print_newline ();
  let answers = List.map ask_question qs in
  Base.List.sexp_of_t Base.Int.sexp_of_t answers                  
               
(*
 * Determine whether a user's profile is up-to-date and, if it is not,
 * update the user's profile.
 *
 * Note that the current setup allows users to spoof other users.
 * This is OK; we assume users are not malicious.
 * There are also some possible issues if users sign up at the
 * same exact time. This is also OK for now.
 *
 * This is all assumed to happen at the command line, when the user first
 * runs make to include the plugin. We will need to ask them to do this
 * by command line for now. If this is a problem for alpha users,
 * we can figure out how to interface with the IDEs as well.
 *)
let sync_profile id =
  let qs = sync_profile_questions id in
  if List.length qs = 0 then
    (* profile is up to date *)
    ()
  else
    (* profile is out of date *)
    let answers = ask_profile_questions qs in
    update_profile id answers;
    print_string "Thank you!"; print_newline ()

(*
 * Get the user ID from the profile, creating it if it doesn't exist
 * Prompt the user for extra information if the server says so
 *)
let user_id =
  let input = open_profile () in
  let id = try input_line input with _ -> "" in
  close_in input;
  if id_is_valid id then
    let _ = sync_profile id in
    id
  else
    let _ =
      print_string
        ("There was an error reading your Analytics profile. " ^
         "Trying to generate a new one. " ^
         "If you continue to encounter this error, or if you have used " ^
         "Analytics with issues in the past, please report a bug " ^
         "in the uwplse/coq-change-analytics Github project.")
    in print_newline ();
    Sys.remove profile_file;
    let input = open_profile () in
    let id = try input_line input with _ -> "" in
    close_in input;
    if id_is_valid id then
      let _ = sync_profile id in
      id
    else
      failwith
        ("Could not create a new Analytics profile. " ^
         "Please report a bug in the uwplse/coq-change-analytics Github " ^
         "project.")
                   
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
 * When there is no network connection, log a message locally to a file
 *)
let log_message_local msg : unit =
  let output = open_out_gen [Open_append; Open_creat] 0o666 temp_log_file in
  output_string output msg;
  close_out output

(*
 * Log a message and send it to the server
 *)
let log_message msg : unit =
  let response =
    Client.post_form ~params:[("msg", [msg])] server_uri >>= fun (resp, body) ->
    let _ = resp |> Response.status |> Code.code_of_status in
    body |> Cohttp_lwt.Body.to_string >|= fun body -> body in
  try
    ignore (Lwt_main.run response)
  with _ ->
    log_message_local msg   

(*
 * Log a message from a buffer and send it to the server
 *)
let log () : unit =
  log_message (buffer_to_string ())

(*
 * Log the buffer remotely or locally
 *)
let log_buffer () : unit =
  let _ =
    if is_debug () then
      Feedback.msg_notice (buffer_to_pp ())
    else
      log ()
  in flush_buffer ()

(*
 * Network outage handling: See if there is an .analytics_log, and if so,
 * send it to the server.
 *)
let handle_outages () =
  if Sys.file_exists temp_log_file then
    let input = open_in temp_log_file in
    let msg = really_input_string input (in_channel_length input) in
    close_in input;
    Sys.remove temp_log_file;
    log_message msg
  else
    ()

(*
 * Output analytics, using opt_debug_analytics to determine
 * whether to do so locally or send output to a server
 *)
let print_analytics (output : Pp.t) (is_exec : bool) : unit =
  let _ = add_to_buffer output in
  if is_exec then
    let now = Unix.time () in
    let last = ! last_sent in
    let elapsed = Pervasives.int_of_float (now -. last) in
    if elapsed >= send_frequency then
      let _ = last_sent := (Unix.time ()) in
      log_buffer ()
    else
      ()
  else
    ()

(*
 * Hooks into the document state
 *)
let print_state_add (v : Vernacexpr.vernac_control) (state : Stateid.t) : unit =
  let exp = Sexp.(List [
                      List [
                          Atom "time";
                          Atom (Pervasives.string_of_float (Unix.gettimeofday ()))];
                      List [
                          Atom "id";
                          Atom (Stateid.to_string state)];
                      List [
                          Atom "user";
                          Atom user_id];
                      List [
                          Atom "session-module";
                          Atom session_module];
                      List [
                          Atom "session";
                          Atom (Pervasives.string_of_float session_id)];
                      List [
                          Atom "Control";
                          List [
                              Atom "StmAdd";
                              List [];
                              Atom (Printf.sprintf "%s " ((Pp.string_of_ppcmds (Ppvernac.pr_vernac v))))]]])
  in print_analytics (Pp.str (Sexp.to_string exp)) false

let print_state_edit (state : Stateid.t) : unit =
  let exp = Sexp.(List [
                      List [
                          Atom "time";
                          Atom (Pervasives.string_of_float (Unix.gettimeofday ()))];
                      List [
                          Atom "user";
                          Atom user_id];
                      List [
                          Atom "session-module";
                          Atom session_module];
                      List [
                          Atom "session";
                          Atom (Pervasives.string_of_float session_id)];
                      List [
                          Atom "Control";
                          List [
                              Atom "StmCancel";
                              List [
                                  Atom (Stateid.to_string state)]]]])
  in print_analytics (Pp.str (Sexp.to_string exp)) false

let print_state_exec (state : Stateid.t) : unit =
  let exp = Sexp.(List [
                      List [
                          Atom "time";
                          Atom (Pervasives.string_of_float (Unix.gettimeofday ()))];
                      List [
                          Atom "user";
                          Atom user_id];
                      List [
                          Atom "session-module";
                          Atom session_module];
                      List [
                          Atom "session";
                          Atom (Pervasives.string_of_float session_id)];
                      List [
                          Atom "Control";
                          List [
                              Atom "StmObserve";
                              Atom (Stateid.to_string state)]]])
  in print_analytics (Pp.str (Sexp.to_string exp)) true

(*
 * Set the hooks for logging
 *)
let _ = Hook.set Stm.document_add_hook print_state_add
let _ = Hook.set Stm.document_edit_hook print_state_edit
let _ = Hook.set Stm.sentence_exec_hook print_state_exec

(*
 * Always log on exit
 *)
let _ = Pervasives.at_exit log_buffer

(*
 * Try to handle outages on exit and on startup
 *)
let _ = Pervasives.at_exit handle_outages
let _ = handle_outages ()
