#lang racket/base

(require "measure.rkt"
         racket/contract
         (for-syntax racket/base racket/syntax))

(provide convert*
         make-dimension-contract
         define-unit
         define-units
         define-dimension-contract
         define-dimension)

(define base->id-converters (make-hash))
(define id->base-converters (make-hash))

;;; This collection offers two calculations modes.
;;; In the first one, which is much like Frink, all calculations are made in SI (or rather, base units),
;;; and the final conversion can be requested in any unit afterwards.
;;; To use this mode, use units by their names, like (m* 2 N).
;;; In the second mode, calculations can be carried out keeping the given units,
;;; and conversion to SI units is done on request.
;;; To use this mode, use units by their symbol, like (m* 2 'N).
;;; The two modes can be combined smoothly.
;;; This also allows to read units from files without them needing to be in SI units.

;;; Some useful conversions: http://en.wikipedia.org/wiki/SI_derived_unit

;;; TODO:
;;; - According to Konrad:
;;; "It would be nice though if
;;; the default units to which everything is converted were modifiable. SI
;;; units are fine for engineering and daily life, but neither for
;;; astrophysics nor for atomic-scale measurements."
;;; - add many SI-derived units: http://en.wikipedia.org/wiki/SI_derived_unit

;;; Returns a measure that tries to express m1 in unit-sym^expt.
(define/contract (convert m1 unit-sym [u-expt 1])
  ([measure? symbol?] [exact-integer?] . ->* . measure?)
  (define conv (hash-ref base->id-converters unit-sym #f))
  (define m-expt (measure-find-unit-expt m1 unit-sym))
  (define d-expt (- u-expt m-expt))
  (cond [(or (= d-expt 0) (not conv))
         m1]
        [(> d-expt 0)
         (for/fold ([m m1]) ([i d-expt])
           (conv m))]
        [(< d-expt 0)
         (measure-inverse 
          (for/fold ([m (measure-inverse m1)]) ([i (- d-expt)])
            (conv m)))]))

;;; Converts m1 to all unit-syms (can be either a dsl-unit or a list of dsl-units).
;;; If unit-syms is 'base, convert m1 to base units.
(define/contract (convert* m1 [unit-syms 'base])
  ([dsl-measure/c] [(or/c symbol? dsl-unit/c 
                          (listof (or/c symbol? dsl-unit/c)))] . ->* . measure?)
  (cond [(eq? unit-syms 'base)
         (measure->base m1)]
        [(dsl-unit/c unit-syms)
         (define u (->unit unit-syms))
         (convert (->measure m1)  (unit-symbol u) (unit-expt u))]
        [(list? unit-syms)
         (for/fold ([m1 m1]) ([u unit-syms])
           (convert* m1 u))]))

;; if unit-sym is #f, all units are converted.
(define (measure->base m1 [unit-sym #f])
  (for/fold ([m1 m1]) ([u (measure-units m1)])
    (define n (unit-expt u))
    (define sym (unit-symbol u))
    (define conv (hash-ref id->base-converters sym #f))
    (if (and (not (zero? n)) 
             conv
             (or (not unit-sym) (eq? unit-sym sym)))
        ((if (< n 0) m/ m*)
         (for/fold ([m1 m1]) ([i (abs n)])
           (conv m1)))
        m1)))

(define-syntax-rule (define-base-unit id id-long)
  (begin
    (define id (->measure 'id))
    (define id-long id)))

(define-syntax-rule (define-unit id id-long unit-exp)
  (begin
    (define id unit-exp)
    (define id-long id)
    (let ([base->id (λ(m)(m* m 'id (m/ id)))]
          [id->base (λ(m)(m* m id '(id -1)))])
      (hash-set! base->id-converters 'id base->id)
      (hash-set! base->id-converters 'id-long base->id)
      (hash-set! id->base-converters 'id id->base)
      (hash-set! id->base-converters 'id-long id->base))))

(define-syntax define-units-helper
  (syntax-rules ()
    [(_ id-base (id id-long (expr ...)))
     (define-unit id id-long (expr ...))]
    [(_ id-base (id id-long ratio))
     (define-unit id id-long (m* ratio id-base))]))

(define-syntax define-units
  (syntax-rules ()
    [(_ (id-base id-base-long) unit-def ...)
     (begin 
       (define-base-unit id-base id-base-long)
       (define-units-helper id-base unit-def)
       ...)]
    [(_ (id-base id-base-long unit-exp) unit-def ...)
     (begin 
       (define-unit id-base id-base-long unit-exp)
       (define-units-helper id-base unit-def)
       ...)]))


(define (make-dimension-contract name m1)
  (make-flat-contract
   #:name name
   #:first-order
   (λ(m2)(measure-units-equal? m1 m2))))

(define-syntax-rule (define-dimension-contract name m1)
  (define name (make-dimension-contract 'name m1)))

(define-syntax (define-dimension stx)
  (syntax-case stx ()
    [(_ name (base-id base-rst ...) units ...)
     (with-syntax ([contract-name (format-id stx "~a/c" #'name)])
       #'(begin
           (define-units (base-id base-rst ...) units ...)
           (define-dimension-contract contract-name base-id)
           ))]))
