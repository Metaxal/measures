#lang racket/base

(require "measure.rkt"
         "convert.rkt"
         "default-units.rkt" ; it would be better if it did not depend on that
         ; but OTOH it's not clear that all function would calculate the right value 
         ; if in a different base than SI
         racket/contract
         racket/math)

(provide (all-defined-out))

;;; Some useful functions and definitions

(define/contract (perimeter radius)
  (length/c . -> . length/c)
  (m* 2 pi radius))

;;;
;;; Area
;;;

(define/contract (disk-area radius)
  (length/c . -> . area/c)
  (m* pi radius radius))

;;;
;;; Volume
;;;

(define/contract (sphere-volume radius)
  (length/c . -> . volume/c)
  (m* 4/3 pi (m^ radius 3)))

(define/contract (cylinder-volume radius height)
  (length/c length/c . -> . volume/c)
  (m* (disk-area radius) height))


;;;
;;; Energy
;;;

(define/contract (kinetic-energy m v)
  (mass/c velocity/c . -> . energy/c)
  (m* 1/2 m v v))

; Fun example:
; http://www.wolframalpha.com/input/?i=30+pound+projectile+at+100+mph&lk=6&ab=c 

(define/contract (projectile-distance v-init a)
  (velocity/c angle/c . -> . length/c)
  (m* v-init v-init (m* (sin (* 2 (measure-quantity a)))) 
      (m/ gravity)))

(define/contract (projectile-height v-init a)
  (velocity/c angle/c . -> . length/c)
  (m* v-init v-init (sqr (sin (measure-quantity a)))
      1/2 (m/ gravity)))

(define/contract (projectile-time v-init a)
  (velocity/c angle/c . -> . time/c)
  (m* 2 v-init (sin (measure-quantity a))
      (m/ gravity)))

; http://www.wolframalpha.com/input/?i=time+to+fall+1000ft&lk=3
(define/contract (time-to-fall height)
  (length/c . -> . time/c)
  (m^ (m* 2 height (m/ gravity)) 1/2))

(define/contract (fall-final-speed height)
  (length/c . -> . velocity/c)
  (m^ (m* gravity 2 height) 1/2))

; Other examples from Wolfram Alpha to try!
; http://www.wolframalpha.com/examples/?src=input

; Todo: symbolic transformations of a (simple) equation
; so that any of the variables can be asked if the others are given.
; Example:
; http://www.wolframalpha.com/input/?i=classical+rocket+equation&lk=3
; This requires special operators that don't actually perform the calculation,
; but make a representation of the formula.



