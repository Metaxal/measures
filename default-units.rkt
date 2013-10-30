#lang racket/base

(require "measure.rkt"
         "convert.rkt"
         racket/math)

(provide (all-defined-out))

;;;
;;; Prefixes (dimension-less)
;;;

;; Prefixes are suffixed by a dot to avoid collision with other unit names
(define-units (one _one (m*))
  (Y.  yotta #e1e24)
  (Z.  zetta #e1e21)
  (E.  exa   #e1e18)
  (P.  peta  #e1e15)
  (T.  tera  #e1e12)
  (G.  giga  #e1e9)
  (M.  mega  #e1e6)
  (k.  kilo  #e1e3)
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

(define-dimension length (m metre)
  (AU  astronomical-unit  149597870700) ; Distance from Earth to Sun.
  (km  kilometre   #e1e3)
  (dm  decimetre   #e1e-1)
  (cm  centimetre  #e1e-2)
  (mm  millimetre  #e1e-3)
  (μm  micron      #e1e-6) ; instead of μ because μ is used as a quantity, 10^-3
  (nm  nanometre   #e1e-9)
  ;
  (Å   angstrom    #e1e-10)
  (ly  light-year  #e9.4607304725808e15) ; light year.
  ;
  (mi  mile  #e1609.344)
  (yd  yard  #e0.9144)
  (ft  foot  #e0.3048)
  (in  inch  #e0.0254))

(define-dimension area (m2 square-metre (m^ m 2))
  (are  a        100)
  (ha   hectare  #e1e4)
  ;
  (sq-ft  square-foot  (m^ ft 2))
  (sq-in  square-inch  (m^ in 2))
  )

(define-dimension volume (m3 cubic-metre (m^ m 3))
  (L   litre       #e1e-3)
  (dL  decilitre   (m* deci L))
  (cL  centilitre  (m* centi L))
  (mL  millilitre  (m* milli L))
  )

(define-dimension mass (kg kilogram)
  (t   tonne      #e1e6)
  (g   gram       #e1e-3)
  (mg  milligram  #e1e-6)
  ;
  (lb  pound  #e0.45359237)
  (oz  ounce  #e0.028)
  )

(define-dimension time (s second)
  (mo   month   2592000)
  (wk   week    604800)
  (h    hour    3600)
  (d    day     86400)
  (min  minute  60)
  (y    year    (m* #e356.25 day))
  )

(define-dimension angle (rad radian (m* 1)) ; dimensionless
  (° degree (m/ pi 180)))

(define-dimension solid-angle (sr steradian (m* 1)))

(define-dimension frequency (Hz hertz (m/ s)))

(define-dimension velocity (m/s meter/second (m/ m s))
 (c  lightspeed  299792458))

(define-dimension acceleration (m/s2 meter/square-second (m/ m s s))
  (gravity standard-gravity #e9.80665)
  )

(define-dimension force (N newton (m* kg m '(s -2)))
  (dyn  dyne         #e1e-5)
  (ozf  ounce-force  #e0.2780138509537812)
  (lbf  pound-force  #e4.4482216152605)
  )

(define-dimension pressure (Pa pascal (m* N '(m -2)))
  (atm   atmosphere             101325)
  (at    atmosphere-technical   #e9.80665e4)
  (bar   _bar                   #e1e5)
  (mmHg  millimetre-of-mercury  #e133.3224) ; approximately
  (cmHg  centimetre-of-mercury  #e1333.224) ; approximately
  (torr  _torr                  101325/760)
  )

(define-dimension power (W watt (m* N m '(s -1)))
  )

(define-dimension energy (J joule (m* m N))
  (cal  calorie        #e4.184)
  (Cal  Calorie        (m* kilo cal))
  (kWh  kilowatt-hour  (m* kilo W h))
  )

(define-dimension electric-current (A ampere))

(define-dimension electric-charge (C coulomb (m* A s)))

(define-dimension voltage (V volt (m/ W A)))

(define-dimension capacitance (F farad (m/ C V)))

(define-dimension resistance (Ω ohm (m/ V A)))

(define-dimension conductance (S siemens (m/ A V)))

(define-dimension magnetic-flux (Wb weber (m* V s)))

(define-dimension magnetic-field-strength (T tesla (m/ Wb m2)))

(define-dimension inductance (H henry (m/ Wb A)))

(define-dimension luminous-intesity (cd candela))

(define-dimension luminous-flux (lm lumen (m* cd sr)))

(define-dimension illuminance (lx lux (m/ lm m2)))

(define-dimension radioactivity (Bq becquerel (m/ s)))

(define-dimension absorbed-dose (Gy gray (m/ J kg)))

(define-dimension equivalent-dose (Sv sievert (m/ J kg)))

(define-dimension amount-of-substance (mol mole))

(define-dimension catalytic-activity (kat katal (m/ mol s)))

(define-dimension temperature (K kelvin)
  (d°C  delta-degree-celsius     1) ; Measures the difference between two degrees
  (d°F  delta-degree-fahrenheit  9/5)
  (°R   degree-rankin            9/5)
  )

