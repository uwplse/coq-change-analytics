#!/usr/bin/env bash

git submodule init
git submodule sync
git submodule update --init --recursive --remote

(cd coq && ./configure -local && make -j 5)
./coq/bin/coq_makefile -f _CoqProject -o Makefile
