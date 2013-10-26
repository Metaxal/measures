#lang racket/base
(require "measures.rkt"
         racket/dict
         racket/contract)

(provide (all-defined-out))

;;; Some conversions between SI units and non-SI units
;;; (no direct conversion between non-SI and non-SI units)

;;; http://en.wikipedia.org/wiki/Conversion_of_units

;;; TODO: 
;;; - Lots of tests?
;;;   (but actually code reviews would be better I guess)

(module+ test 
  (require rackunit)
  (define (check-converter a->b b->a va [epsilon 0.])
    (define vb (a->b va))
    (define vc (b->a vb))
    (check-= (measure-quantity va)
             (measure-quantity vc)
             epsilon)))


(define converters (make-hash))

(define (add-converters! from-sym to-sym from->to to->from)
  (hash-set! converters (list from-sym to-sym) from->to)
  (hash-set! converters (list to-sym from-sym) to->from))

;; Returns two procedures that convert measures of unit from-sym to measures of unit to-sym
;; (and vice-versa)
;; with to = from×ratio + offset.
;; (offset is an offset on the to-sym unit)
;; Converters can even be used with values than "contain" a from-sym or to-sym unit, 
;; without needing to be of the exact from or to unit.
(define/contract (make-affine-converters from-sym to-sym ratio offset)
  (symbol? symbol? number? number? . -> . (values procedure? procedure?))
  (define from->to (λ(v)(measure-offset 
                         (m* v ratio `(1 ,to-sym (,from-sym -1)))
                         offset)))
  (define to->from (λ(v)(m* (measure-offset v (- offset))
                            (/ ratio) `(1 ,from-sym (,to-sym -1)))))
  (add-converters! from-sym to-sym from->to to->from)
  (values from->to to->from))

(define (make-linear-converters from-sym to-sym ratio)
  (make-affine-converters from-sym to-sym ratio 0))

(define (convert m from-sym to-sym)
  (define expt (measure-find-unit-expt m from-sym))
  (if (= 0 expt)
      m
      (let* ([key (if (> expt 0) 
                      (list from-sym to-sym)
                      (list to-sym from-sym))]
             [conv (dict-ref converters key)])
        (for/fold ([m m]) ([i (abs expt)])
          (conv m)))))


;;;
;;; Temperature
;;;
;;; http://en.wikipedia.org/wiki/Temperature_conversion_formulas

(define-values (kelvin->farenheit farenheit->kelvin)
  (make-affine-converters 'K '°F 9/5 -459.67))

(module+ test
  (check-converter kelvin->farenheit farenheit->kelvin (m 5.0 'K)))

(define-values (kelvin->celsius celsius->kelvin)
  (make-affine-converters 'K '°C 1 -273.15))

(define (kelvin->celsius2 k)
  (m* (m- k '(273.15 K)) 
      '(1 °C (K -1))))

(define (celsius->kelvin2 c)
  (m* (m+ c '(273.15 °C)) 
      '(1 K (°C -1))))

(module+ test
  (check-converter kelvin->celsius celsius->kelvin (m 5.0 'K)))

;;;
;;; Mass
;;;

(define-values (pound->kilogram kilogram->pound)
  (make-linear-converters 'lb 'kg 0.45359237))

;;;
;;; Time
;;;

(define-values (hour->second second->hour)
  (make-linear-converters 'h 's 3600))

(define-values (minute->second second->minute)
  (make-linear-converters 'min 's 60))

;;;
;;; Space
;;;

(define-values (mile->meter meter->mile)
  (make-linear-converters 'mi 'm 1609.344))

(module+ test
  (check-equal?
   (measure->value (convert (convert (m 50 'mi '(h -1)) 'mi 'm)
                            'h 's))
   '(22.352 m (s -1))))
