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

Note that this collection does _not_ automatically convert between measures,
for example pounds to grams, but it should not be too difficult to add that
on top of it.
However, explicit conversions are handled correctly, and units with exponent 0 are removed:
```racket
> (measure->value
   (m* '(52.8 ft (s -1))
       (m/ '(1 mi)
           '(5280 ft))
       (m/ '(3600 s)
           '(1 h))))
'(36.0 mi (h -1))
```

Some useful conversions can be found here:
http://en.wikipedia.org/wiki/SI_derived_unit

You may also be interested in Doug Williams scientific collection:
http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html

