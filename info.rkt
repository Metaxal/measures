#lang info

(define deps
  '("base"))

(define build-deps
  '("at-exp-lib" "rackunit-lib" "scribble-lib" "racket-doc"))

(define scribblings
  '(["README.scrbl" () (library) "measures"]))
