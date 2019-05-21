#!/usr/bin/env bash

(cd coq && ./configure -local && make -j 5)
coq_makefile -f _CoqProject CAMLPKGS = "-package cohttp -package cohttp-lwt-unix -package lwt" -o Makefile
