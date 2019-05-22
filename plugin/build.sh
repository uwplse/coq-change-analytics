#!/usr/bin/env bash

(cd coq && ./configure -local && make -j 5)
./coq/bin/coq_makefile -f _CoqProject -o Makefile
