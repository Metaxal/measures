Units and Measurements
======================

Units and measurements in Racket.

A `unit` is a symbol and an exponent.
A `measure` is a number and a set of units.

Basic arithmetic operations (`m+` `m-` `m*` `m/`) are defined to work with measures.

To ease human interaction, measures can be written in an simple Domain Specific Language, that turns list-based numbers to measures.
A DSL measure can then be:
* a number alone,
* a list with a number followed by one or more DSL units.

A DSL unit can be:
* a symbol alone (taking the 1 exponent by default),
* a list with a symbol and an exponent.

The procedure `m` is a helper to turn a DSL measure into a `measure`.

Example:
```racket
> (require measures)

> (m 3)
(measure 3 (set))

> (m 3 's)
(measure 3 (set (unit 's 1)))

> (m 3 's '(m -1))
(measure 3 (set (unit 's 1) (unit 'm -1)))
```
The arithmetic operators automatically convert DSL measures into `measures`:
```racket
> (m* '(3 s) 5 '(10 m))
(measure 150 (set (unit 'm 1) (unit 's 1)))
```
Measures can be turned back to human readable values with `measure->value':
```racket
> (measure->value (m* '(3 s) 5 '(10 m)))
'(150 m s)

> (measure->value
   (m* '(3 s) '(5 (s -1))))
15
```

Adding or subtracting measures with different units raises an `exn:fail:unit` exception:
```racket
> (measure->value (m+ '(3 m (h -1)) '(2 m h)))
Error: Measures must have the same units.
Got: #<set: #(struct:unit m 1) #(struct:unit h 1)> and #<set: #(struct:unit m 1) #(struct:unit h -1)>

> (measure->value (m+ '(3 m (h -1)) '(2 m (h -1))))
'(5 m (h -1))
```

Conversions between units can be performed using the `convert*` function.
It takes a measure and a list of conversions and returns the converted measure.
Units with exponent 0 are removed, and conversions between non-SI units are possible
only if there exists an intermediate SI unit.

For example, to convert feet/seconds to miles/hour:
```racket
> (measure->value
   (convert* '(52.8 ft (s -1))
             '(mi h)))
'(36.0 mi (h -1))
```
To know how many cubic meters there are in 100 cubic centimeters:
```racket
> (measure->value
   (convert* '(100 (cm 3))
             '(m)))
'(0.0001 (m 3))
```
Or how many degree Celsius make 100 degree Fahrenheit:
```racket
> (measure->value
   (convert* '(100 °F)
             '(°C)))
'(37.77777777777783 °C)
```

Some useful conversions can be found here:
http://en.wikipedia.org/wiki/SI_derived_unit

You may also be interested in Doug Williams scientific collection:
http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html

