#lang racket/base
(require "measures.rkt")

(provide (all-defined-out))

;;; Some conversions between SI units and non-SI units
;;; (no direct conversion between non-SI and non-SI units)

;;; http://en.wikipedia.org/wiki/Conversion_of_units

;;; TODO: 
;;; - Lots of tests?
;;;   (but actually code reviews would be better I guess)
;;; - converters that can convert values that *contain* one dimension (possibly with non-1 exponent)
;;;   e.g. (km^2/s -> m^2/s)

(module+ test 
  (require rackunit)
  (define (check-converter a->b b->a va [epsilon 0.])
    (define vb (a->b va))
    (define vc (b->a vb))
    (check-= (measure-quantity va)
             (measure-quantity vc)
             epsilon)))


;; Returns two procedures that convert measures of unit from-sym to measures of unit to-sym
;; (and vice-versa)
;; by multiplying the first by the specified ratio.
;; Scalar converters can even be used with values than "contain" a from-sym or to-sym unit.
(define (make-scalar-converters from-sym to-sym ratio)
  (values
   (λ(v)(m* v ratio `(1 ,to-sym (,from-sym -1))))
   (λ(v)(m* v (/ ratio) `(1 ,from-sym (,to-sym -1))))))
;;;
;;; Temperature
;;;
;;; http://en.wikipedia.org/wiki/Temperature_conversion_formulas

(define (kelvin->farenheit k)
  (m- (m* k '(9/5 °F (K -1)))
      '(459.67 °F)))

(define (farenheit->kelvin f)
  (m* '(5/9 K (°F -1)) (m+ f '(459.67 °F))))

(module+ test
  (check-converter kelvin->farenheit farenheit->kelvin (m 5.0 'K)))

(define (kelvin->celsius k)
  (m* (m- k '(273.15 K)) 
      '(1 °C (K -1))))

(define (celsius->kelvin c)
  (m* (m+ c '(273.15 °C)) 
      '(1 K (°C -1))))

(module+ test
  (check-converter kelvin->celsius celsius->kelvin (m 5.0 'K)))

;;;
;;; Mass
;;;

(define-values (pound->kilogram kilogram->pound)
  (make-scalar-converters 'lb 'kg 0.45359237))

;;;
;;; Time
;;;

(define-values (hour->second second->hour)
  (make-scalar-converters 'h 's 3600))

(define-values (minute->second second->minute)
  (make-scalar-converters 'min 's 60))

;;;
;;; Space
;;;

(define-values (mile->meter meter->mile)
  (make-scalar-converters 'mi 'm 1609.344))
