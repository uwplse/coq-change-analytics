#!/usr/bin/env bash

echo "Thank you for installing Coq Change Analytics! We'll first install a few dependencies."

opam install sexplib cohttp cohttp-lwt-unix

echo "Done. Now, to run this plugin, you need the latest Coq version (master). Do you already have this version of Coq installed? [y/n]"

read_in () {
  while :
  do
    read input

    if [[ "$input" = "y" ]]; then
      return 0
    else
      if [[ "$input" = "n" ]]; then
        return 1
      else 
        echo "Invalid input. Please try again."
      fi
    fi
  done
}

if read_in; then
  echo "OK. We will build this plugin with your Coq version. First, let's generate a Makefile."
  coq_makefile -f _CoqProject -o Makefile
  cp ./make-user ./make
  echo "Done. From now on, run make in this directory to build the plugin."
else
  echo "Would you like for us to pull the latest Coq for you? [y/n]"
  
  if read_in; then
    echo "OK, pulling the latest Coq for you."
    git submodule init
    git submodule sync
    git submodule update --init --recursive --remote

    echo "Would you prefer to install this version of Coq locally, so that you can keep other versions of Coq around on your computer more easily? [y/n]"

    if read_in; then
      echo "OK, installing Coq locally. Hang tight."
      (cd coq && ./configure -local && make -j 5)
      echo "All set. Now, let's generate a Makefile."
      ./coq/bin/coq_makefile -f _CoqProject -o Makefile
      cp ./make-local ./make
      echo "Done. From now on, run ./make in this directory to build the plugin."
      echo "Note that you will need to use this local copy of Coq to build any projects that use this plugin."
    else
      echo "OK, installing Coq. Hang tight."
      (cd coq && make -j 5)
      echo "All set. Now, let's generate a Makefile."
      coq_makefile -f _CoqProject -o Makefile
      cp ./make-user ./make
      echo "Done. From now on, run ./make in this directory to build the plugin."
      echo "Note that you will need to use the installed version of Coq to build any projects that use this plugin."
    fi
  else
    echo "OK. Please install the latest version of Coq separately, and then run this script again."
  fi
fi

