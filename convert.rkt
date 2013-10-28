#lang racket/base

(require "measure.rkt"
         racket/contract)

(provide (all-defined-out))

(define si->id-converters (make-hash))
(define id->si-converters (make-hash))

;;; This collection offers two calculations modes.
;;; In the first one, which is much like Frink, all calculations are made in SI,
;;; and the final conversion can be requested in any unit afterwards.
;;; To use this mode, use units by their names, like (m* 2 N).
;;; In the second mode, calculations can be carried out keeping the given units,
;;; and conversion to SI units is done on request.
;;; To use this mode, use units by their symbol, like (m* 2 'N).
;;; The two modes can be combined smoothly.

;;; This also allows to read units from files without them needing to be in SI units.

;;; Returns a measure that tries to express m1 in unit-sym^expt.
(define/contract (convert m1 unit-sym [u-expt 1])
  ([measure? symbol?] [exact-integer?] . ->* . measure?)
  (define conv (hash-ref si->id-converters unit-sym #f))
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
;;; If unit-syms is 'SI, convert m1 to SI units.
(define/contract (convert* m1 [unit-syms 'SI])
  ([dsl-measure/c] [(or/c symbol? dsl-unit/c 
                          (listof (or/c symbol? dsl-unit/c)))] . ->* . measure?)
  (cond [(eq? unit-syms 'SI)
         (measure->si m1)]
        [(dsl-unit/c unit-syms)
         (define u (->unit unit-syms))
         (convert (->measure m1)  (unit-symbol u) (unit-expt u))]
        [(list? unit-syms)
         (for/fold ([m1 m1]) ([u unit-syms])
           (convert* m1 u))]))

;; if unit-sym is #f, all units are converted.
(define (measure->si m1 [unit-sym #f])
  (for/fold ([m1 m1]) ([u (measure-units m1)])
    (define n (unit-expt u))
    (define sym (unit-symbol u))
    (define conv (hash-ref id->si-converters sym #f))
    (if (and (not (zero? n)) 
             conv
             (or (not unit-sym) (eq? unit-sym sym)))
        ((if (< n 0) m/ m*)
         (for/fold ([m1 m1]) ([i (abs n)])
           (conv m1)))
        m1)))

(define-syntax-rule (define-si-unit id id-long)
  (begin
    (define id (->measure 'id))
    (define id-long id)))

(define-syntax-rule (define-unit id id-long unit-exp)
  (begin
    (define id unit-exp)
    (define id-long id)
    (let ([si->id (λ(m)(m* m 'id (m/ id)))]
          [id->si (λ(m)(m* m id '(id -1)))])
      (hash-set! si->id-converters 'id si->id)
      (hash-set! si->id-converters 'id-long si->id)
      (hash-set! id->si-converters 'id id->si)
      (hash-set! id->si-converters 'id-log id->si))))

(define-syntax define-units-helper
  (syntax-rules ()
    [(_ id-si (id id-long (expr ...)))
     (define-unit id id-long (expr ...))]
    [(_ id-si (id id-long ratio))
     (define-unit id id-long (m* ratio id-si))]))

(define-syntax define-units
  (syntax-rules ()
    [(_ (id-si id-si-long) unit-def ...)
     (begin 
       (define-si-unit id-si id-si-long)
       (define-units-helper id-si unit-def)
       ...)]
    [(_ (id-si id-si-long unit-exp) unit-def ...)
     (begin 
       (define-unit id-si id-si-long unit-exp)
       (define-units-helper id-si unit-def)
       ...)]))

;;;
;;; Prefixes (dimension-less)
;;;

;; Prefixes are suffixed by a dot to avoid collision with other unit names
(define-units (_SI_u _SI_unity (m*))
  (Y.  yotta 1e24)
  (Z.  zetta 1e21)
  (E.  exa   1e18)
  (P.  peta  1e15)
  (T.  tera  1e12)
  (G.  giga  1e9)
  (M.  mega  1e6)
  (k.  kilo  1e3)
  (h.  hecto 100)
  (da. deca  10)
  (d.  deci  1/10)
  (c.  centi 1/100)
  (m.  milli #e1e-3)
  (μ.  micro #e1e-6)
  (n.  nano  #e1e-9)
  (p.  pico  #e1e-12)
  (f.  femto #e1e-15)
  (a.  ato   #e1e-18)
  (z.  zepto #e1e-21)
  (y.  yocto #e1e-24))


;;;
;;; Length
;;;

(define-units (m metre)
  (AU  astronomical-unit  149597870700) ; Astronomical Unit. Distance from Earth to Sun.
  (km  kilometre   1e3)
  (dm  decimetre   #e1e-1)
  (cm  centimetre  #e1e-2)
  (mm  millimetre  #e1e-3)
  (μm  micron      #e1e-6) ; instead of µ because µ is used as a quantity, 10^-3
  (nm  nanometre   #e1e-9)
  ;
  (Å   angstrom    #e1e-10)
  (ly  light-year  #e9.4607304725808e15) ; light year.
  ;
  (mi  mile  #e1609.344)
  (yd  yard  #e0.9144)
  (ft  foot  #e0.3048)
  (in  inch  #e0.0254))

;;;
;;; Area
;;;

(define-units (m2 square-metre (m* m m))
  (are  a        1e2)
  (ha   hectare  1e4)
  ;
  (sq-ft  square-foot  (m* ft ft))
  (sq-in  square-inch  (m* in in))
  )

; Can be deduced from the lengths, by adding correct exponents

;;;
;;; Volume
;;;

(define-units (m3 cubic-metre (m* m m m))
  (L  litre  #e1e-3)
  (dL  decilitre (m/ L 10))
  )


;;;
;;; Mass
;;;

(define-units (kg kilogram)
  (t   tonne      1e6)
  (g   gram       #e1e-3)
  (mg  milligram  #e1e-6)
  ;
  (lb  pound  #e0.45359237)
  (oz  ounce  #e0.028)
  )

;;;
;;; Time
;;;

(define-units (s second)
  (mo   month   2592000)
  (wk   week    604800)
  (h    hour    3600)
  (d    day     86400)
  (min  minute  60))

;;;
;;; Force
;;;

(define-units (N newton (m* kg m '(s -2)))
  (dyn  dyne         #e1e-5)
  (ozf  ounce-force  #e0.2780138509537812)
  (lbf  pound-force  #e4.4482216152605)
  )

;;;
;;; Pressure
;;;

(define-units (Pa pascal (m* N '(m -2)))
  (atm   atmosphere             101325)
  (at    atmosphere-technical   #e9.80665e4)
  (bar   _bar                   1e5)
  (mmHg  millimetre-of-mercury  #e133.3224) ; approximately
  (cmHg  centimetre-of-mercury  #e1333.224) ; approximately
  (torr  _torr                  101325/760)
  )

