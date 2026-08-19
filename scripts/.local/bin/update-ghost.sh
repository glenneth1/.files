#!/usr/bin/env bash

clear;

 aura -Syyu

 # -t emacs-29
 pushd $HOME/system_scripts/ || exit 1

 clear; ./build-emacs.sh -t master &&

     pushd $HOME/SourceCode/emacs/ || exit 1

 ./src/emacs --version &&
     git log

