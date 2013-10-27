#lang racket/base
(require "measures.rkt"
         racket/dict
         racket/match
         racket/contract)

(provide (all-defined-out))

;;; Some conversions between SI units and non-SI units
;;; (no direct conversion between non-SI and non-SI units)

;;; http://en.wikipedia.org/wiki/Conversion_of_units

;;; TODO: 
;;; - conversion with multiple dimensions: Litre -> m^3; Newton -> kg.m/s^2
;;; - Lots of tests

(module+ test 
  (require rackunit)
  
  (define (check-measure=? m1 m2 [epsilon 0.])
    (check measure-units-equal? m1 m2)
    (check-= (measure-quantity m1)
             (measure-quantity m2)
             epsilon))
  
  (define (check-converter a->b b->a ma [epsilon 0.])
    (define mb (a->b ma))
    (define mc (b->a mb))
    (check-measure=? ma mc epsilon)))


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

(define (add-linear-converters! from-to-ratio-list)
  (for ([v from-to-ratio-list])
    (match v
      [(list from-sym to-sym ratio)
       (make-linear-converters from-sym to-sym ratio)])))


;; Converts all from-sym units of m to to-sym units, whatever the exponent.
;; When the exponent is negative, instead of invert-convert-invert,
;; we could simply apply the opposite (to to from) transform,
;; but this work only if the conversion is linear, e.g. not for °F to Kelvin.
;; OTOH, non-linear conversions are not "safe" (e.g. to convert °F/s to °C/s,
;; the non-linear transform probably does not apply here, as the quantity is
;; probably the difference between two °F)
(define (convert m1 from-sym to-sym)
  (define expt (measure-find-unit-expt m1 from-sym))
  (if (= 0 expt)
      m1
      (let* ([key (list from-sym to-sym)
                  #;(if (> expt 0) 
                      (list from-sym to-sym)
                      (list to-sym from-sym))]
             [conv (dict-ref converters key)]
            [m-out (for/fold ([m (if (< expt 0) (measure-inverse m1) m1)]
                        ) ([i (abs expt)])
                      (conv m))])
        (if (< expt 0)
            (measure-inverse m-out)
            m-out))))


;;;
;;; Temperature
;;;
;;; http://en.wikipedia.org/wiki/Temperature_conversion_formulas

(define-values (kelvin->farenheit farenheit->kelvin)
  (make-affine-converters 'K '°F 9/5 -459.67))

(define-values (kelvin->celsius celsius->kelvin)
  (make-affine-converters 'K '°C 1 -273.15))

(module+ test
  (check-converter kelvin->farenheit farenheit->kelvin (m 5.0 'K))
  (check-converter kelvin->celsius celsius->kelvin (m 5.0 'K))
  
  (check-measure=? (convert (m 100 '°F) '°F 'K)
                   (m 310.928 'K) 0.01)
  
  (check-measure=? (convert (m 100 '°C) '°C 'K)
                   (m 373.15 'K) 0.01)
  )

;;;
;;; Length
;;;

(add-linear-converters!
 '((AU m 149597870700) ; Astronomical Unit. Distance from Earth to Sun.
   (km m 1e3)
   (dm m 1e-1)
   (cm m 1e-2)
   (mm m 1e-3)
   (μ  m 1e-6)
   (nm m 1e-9)
   ;
   (Å  m 1e-10)
   (ly m 9.4607304725808e15) ; light year. Distance light travels in vacuum in 365.25 days
   ;
   (mi m 1609.344)
   (yd m 0.9144)
   (ft m 0.3048)
   (in m 0.0254)))

(module+ test
  (check-measure=?
   (convert (m 100 '(ft 2)) 'ft 'm)
   (m 9.2903 '(m 2))
   0.01)
  
  (check-measure=?
   (convert (convert (m 50 'mi '(h -1)) 'mi 'm)
            'h 's)
   (m 22.352 'm '(s -1)))
  
  )

;;;
;;; Mass
;;;

(add-linear-converters!
 '((lb kg 0.45359237)
   (oz kg 28e-3)
   (g kg 1e-3)
   (mg kg 1e-6)
   (t kg 1e6)))

(module+ test
  (check-measure=? (convert (m 100 'kg) 'kg 'lb)
                   (m 220.462 'lb) 0.01)
  
  )

;;;
;;; Volume
;;;

(add-linear-converters!
 '())

;;;
;;; Time
;;;

(add-linear-converters!
  '((h s 3600)
    (min s 60)))

