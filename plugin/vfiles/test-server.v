Require Import Analytical.Analytics.

Require Import Nat.
Theorem nat_refl : forall x : nat, x = x.
Proof.
reflexivity.
Qed.
(*
 * To test the plugin, write and modify Coq code of your choice here
 * using your favorite IDE.
 *)