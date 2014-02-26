#lang racket/base

(require "measure.rkt"
         "convert.rkt"
         racket/math)

(provide (all-defined-out))

;; Prefixes (dimension-less)
;; Prefixes are suffixed by a dot to avoid collision with other unit names
(define-units (one () (m*))
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
  (km  kilometre   #e1e3)
  (dm  decimetre   #e1e-1)
  (cm  centimetre  #e1e-2)
  (mm  millimetre  #e1e-3)
  (μ   micron      #e1e-6)
  (nm  nanometre   #e1e-9)
  ;
  (AU  astronomical-unit  149597870700) ; Distance from Earth to Sun.
  (Å   angstrom           #e1e-10)
  ; English International
  ;http://en.wikipedia.org/wiki/United_States_customary_units
  (in  inch  #e0.0254)
  (ft  foot  (m* 12 inch)) ; US Survey
  (yd  yard  (m* 3 foot))
  (mi  mile  (m* 1760 yard))
  ;
  (marathon () 42195)
  (semi-marathon () (m/ marathon 2))
  )

(define-dimension area (m2 square-metre (m^ m 2))
  (are  a        100)
  (ha   hectare  #e1e4)
  ;
  (b  barn #e1e-28)
  ;
  (sq-ft  square-foot  (m^ ft 2))
  (sq-in  square-inch  (m^ in 2))
  )

(define-dimension volume (m3 cubic-metre (m^ m 3))
  (L   (l litre)        #e1e-3)
  (dL  (dl decilitre)   (m* deci L))
  (cL  (cl centilitre)  (m* centi L))
  (mL  (ml millilitre)  (m* milli L))
  ; Liquid US measures
  (gal   gallon         (m* 231 (m^ inch 3)))
  (qt    quart          (m/ gallon 4))
  (pt    pint           (m/ quart 2))
  (gi    gill           (m/ pint 4))
  (floz  fluid-ounce    (m/ pint 16))
  (Tsp   tablespoon     (m* fluid-ounce 2))
  (fldr  fluid-dram     (m/ fluid-ounce 8))
  (tsp   teaspoon       (m/ tablespoon 3))
  (lbbl  liquid-barrel  (m* #e31.5 gallon))
  (bbl   oil-barrel     (m* 42 gallon))
  ; http://en.wikipedia.org/wiki/Drop_%28unit%29
  (gtt drop (m/ millilitre 20))
  )

(define-dimension mass (kg kilogram)
  (amu atomic-mass-unit  1.6605402e-27)
  ;
  (t   tonne      #e1e3)
  (g   gram       #e1e-3)
  (mg  milligram  #e1e-6)
  (µg  microgram  #e1e-9)
  ; Avoirdupoids
  (lb   pound          #e0.45359237)
  (gr   grain          (m/ pound 7000))
  (oz   ounce          (m/ pound 16))
  (dr   dram           (m/ ounce 16))
  (cwt  hundredweight  (m* 100 pound)) ; US
  (ton  short-ton      (m* 2000 pound))
  ;
  (me electron-mass  9.1093826e-31)
  )

; http://en.wikipedia.org/wiki/Density
; http://en.wikipedia.org/wiki/Densities_of_the_elements_%28data_page%29
; At standard conditions for temperature and pressure, 
; that is, 273.15 K (0.00 °C) and 100 kPa (0.987 atm).
(define-dimension density (ρ kg/m3 (m/ kg m3))
  (g/cm3 () (m/ g (m^ cm 3)))
  ;
  (ρ-air         air-density         1.2) ; at sea level
  (ρ-helium      helium-density      0.179)
  (ρ-water       water-density       1000)
  (ρ-salt-water  salt-water-density  1030)
  (ρ-ice         ice-density         916.7) ; below 0°C
  ; See chemical-elements for more values
) 

(define-dimension time (s second)
  (min  minute  60)
  (h    hour    (m* 60 minute))
  (d    day     (m* 24 hour))
  (wk   week    (m* 7 day))
  (mo   month   (m* 30 day))
  (y    year    (m* #e365.25 day))
  )

; Radians are actually dimensionless, but still keep the symbol to ensure type-safety.
; Otherwise one would be allowed to add
; radians with degrees, since both are dimensionless
(define-dimension angle (rad radian)
  (° degree (m/ (m* pi rad) 180)))

(define-dimension solid-angle (sr steradian))

(define-dimension frequency (Hz hertz (m/ s)))

(define-dimension velocity (m/s metre/second (m/ m s))
  (c light-speed 299792458)
  (sound-speed () #e343.2) ; at 20° in dry air
  ;
  (km/h kilometre-per-hour (m/ km h))
  ;
  (mi/h (mile-per-hour mph) (m/ mi h))
  )

; 1 m/s2 = 1 J/(m×kg)s
(define-dimension acceleration (m/s2 metre/square-second (m/ m s s))
  (gravity standard-gravity #e9.80665)
  ;; http://en.wikipedia.org/wiki/Bicycle_performance#Energy_efficiency
  ; A 80kg person walking for 3km uses (convert* (m* 80 kg 3 km walking-acc) 'Cal) kilo calories
  (walking-acc () 3.78) ; m/s2 = kilo J/(km kg)
  (running-acc () (m* walking-acc))
  (cycling-acc () 1.62)
  (swimming-acc () 16.96)
  ; Energy required to lift 10kg for 2 m high: (convert* (m* lifting-energy 2 m 10 kg) 'J)
  (lifting-acc () (m* gravity))
  )

(define-dimension force (N newton (m* kg m '(s -2)))
  (dyn  dyne         #e1e-5)
  (ozf  ounce-force  #e0.2780138509537812)
  (lbf  pound-force  #e4.4482216152605)
  )

(define-dimension pressure (Pa pascal (m* N '(m -2)))
  (atm   atmosphere             101325)
  (at    atmosphere-technical   #e9.80665e4)
  (bar   ()                     #e1e5)
  (mbar  millibar               100)
  (mmHg  millimetre-of-mercury  #e133.3224) ; approximately
  (cmHg  centimetre-of-mercury  #e1333.224) ; approximately
  (torr  ()                     101325/760)
  )

(define-dimension power (W watt (m* N m '(s -1)))
  )

(define-dimension energy (J joule (m* m N))
  (cal  calorie        #e4.184)
  (Cal  Calorie        (m* kilo cal))
  (kWh  kilowatt-hour  (m* kilo W h))
  ;
  (eV   electronvolt       1.602176565e-19)
  (meV  millielectronvolt  (m* milli electronvolt))
  (μeV  microelectronvolt  (m* micro electronvolt))
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

; http://en.wikipedia.org/wiki/Conversion_of_units_of_temperature
(define (kelvin->celsius m)
  (m- m 273.15))
(define (celsius->kelvin c)
  (m+ m 273.15))
(define (kelvin->fahrenheit m)
  (m- (m* m 9/5) 459.67))
(define (fahrenheit->kelvin m)
  (m* (m+ m 459.67) 5/9))

(define-unit h-plank  planck-constant  (m* 6.62606957e-34 J s))
(define-unit ħ        h-bar            (m/ h (m* 2 pi)))

(define-unit light-year   (m* c year))
(define-unit light-second (m* c second))
(define-unit light-minute (m* c minute))


