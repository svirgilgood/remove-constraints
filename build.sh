#!/usr/bin/env bash

sbcl --noinform --load package.lisp --eval '(save-lisp-and-die "remove-constraints" :toplevel (function remove-constraints:main) :executable t :compression t :save-runtime-options t)'
