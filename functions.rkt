#lang racket/base

(require "measure.rkt"
         "convert.rkt"
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



