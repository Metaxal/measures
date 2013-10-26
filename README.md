Units and Measurements
======================

Units and measurements in Racket.

A `unit` is a symbol associated with an exponent.
A `measure` is a number associated with a set of units.

Basic arithmetic operations (`m+` `m-` `m*` `m/`) are defined to work with measures.

A simple Domain Specific Language turns list-based numbers to measures.
A DSL measure can then be:
* a number alone,
* a list with a number followed by one or more DSL unit.

A DSL unit can be:
* a symbol alone (taking the 1 exponent by default),
* a list with a symbol and an exponent.

Example:
```racket
> (require measures)
> (m* '(3 s) 5 '(10 m))
(measure 150 (set (unit 'm 1) (unit 's 1)))
```
Measures can be turned back to human readable values with `measure->':
```racket
> (measure-> (m* '(3 s) 5 '(10 m)))
'(150 m s)
```

Adding or subtracting measure with the wrong types raises an `exn:fail:unit` exception.

Note that this collection does _not_ automatically convert between measures,
for example pounds to grams, but it should not be too difficult to add that
on top of it.
However, explicit conversions are handled correctly, and units with exponent 0 are removed:
```racket
> (measure->
   (m* '(52.8 ft (s -1))
       (m/ '(1 mi)
           '(5280 ft))
       (m/ '(3600 s)
           '(1 h))))
'(36.0 mi (h -1))
```

You may also be interested in Doug Williams scientific collection:
http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html

