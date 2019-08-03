(*
 * Consent form text and agreement
 * Client-side modification of this text is a breach of the study agreement
 *)

(* --- Consent --- *)

let consent_form_text =
  "CONSENT FORM\n" ^
  "-------------\n" ^
  "By participating in this study, you agree that you are over 18, " ^
  "fluent in English, and have been using Coq for at least a year. " ^
  "You agree to answer the registration questions truthfully, and " ^
  "you agree not to spoof other users or otherwise purposely provide " ^
  "misleading data. You agree to keep the plugin enabled whenever possible " ^
  "during the data collection period of August 7th through September 7th, " ^
  "and to inform the study organizers if you must disable the plugin " ^
  "for any reason."

let consent_q1 =
  "I have read the consent form. [y/n]"

let consent_q2 =
  "I understand and agree to all of the above. [y/n]"

(* --- Data Policy --- *)

let data_policy_text =
  "DATA POLICY\n" ^
  "-------------\n" ^
  "By participating in this study, you consent to the following data policy: " ^
  "The plugin will collect data on the changes (code executed in Coq, " ^ 
  "along with the time at which the code was executed) " ^
  "that you make while developing proofs during the data collection period " ^
  "of August 7th through September 7th.\n\n" ^
  "During registration, the plugin will also collect and store " ^
  "information on your level of experience in Coq, the purpose for which " ^
  "and frequency with which you use Coq, and about your development " ^
  "processes and environment. This information will be stored " ^
  "with a unique identifier, and the unique identifier will be linked to the " ^
  "collected data as well. The server will collect IP addresses; " ^
  "the IP addresses will not be stored with the resulting data.\n\n" ^
  "The collected data (unique identifiers, code changes, and answers " ^
  "to registration questions) will be used to guide the development " ^
  "of a proof patching tool and of a machine learning tool. " ^
  "The data will also be used in a publication, " ^
  "and it will be publicly available for use by other researchers. " ^
  "There will be no identifiable links between personally " ^
  "identifiable information and the data in any publications, " ^
  "or in the publicly available dataset."

let data_policy_q1 =
  "I have read the data policy. [y/n]"

let data_policy_q2 =
  "I understand and consent to all of the above. [y/n]"
