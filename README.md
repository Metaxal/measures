# 1. Units and Measurements

Units and measurements in Racket.

First some **warnings**:

* This collection has not been extensively tested. Use with caution and
  please [report any error that you
  find](https://github.com/Metaxal/measures/issues)

* Be cautious with non-linear converters (e.g., °F to K), as converting
  a temperature difference is not the same as converting a temperature.

## 1.1. Basic definitions

A `unit` is a symbol and an exponent. A `measure` is a number and a set
of units.

Basic arithmetic operations (`m+` `m-` `m*` `m/` `m^`) are defined to
work with measures.

To ease human interaction, measures can be written in an simple Domain
Specific Language (DSL). A DSL measure can then be:

* a (struct) measure,

* a number,

* a DSL unit,

* a list with a number followed by one or more DSL units.

A DSL unit can be:

* a (struct) unit,

* a symbol alone (taking the exponent 1 by default),

* a list with a symbol and an exponent.

You can use the multiplication operator `m*` to easily build measures.

```racket
> (m* 3)                                  
(measure 3 (set))                         
> (m* 3 's)                               
(measure 3 (set (unit 's 1)))             
> (m* 3 's '(m -1))                       
(measure 3 (set (unit 's 1) (unit 'm -1)))
```

The arithmetic operators automatically convert DSL measures into
`measures`:

```racket
> (m+ 2 3)                      
(measure 5 (set))               
> (m/ 3 '(2 s))                 
(measure 3/2 (set (unit 's -1)))
```

Measures can be turned back to human readable values with
`measure->value`:

```racket
> (measure->value (m* '(3 s) 5 '(10 m)))  
'(150 m s)                                
> (measure->value (m* '(3 s) '(5 (s -1))))
15                                        
```

Adding or subtracting measures with different units raises an
`exn:fail:unit` exception:

```racket
> (measure->value (m+ '(3 m (h -1)) '(2 m h)))        
Error: Measures must have the same units.             
Got: #<set: #(struct:unit m 1) #(struct:unit h 1)> and
#<set: #(struct:unit m 1) #(struct:unit h -1)>        
> (measure->value (m+ '(3 m (h -1)) '(2 m (h -1))))   
'(5 m (h -1))                                         
```

## 1.2. Units and conversions

All units have a short and a long name. The short name is the standard
symbol, and the long name is more descriptive:

```racket
> mmHg                                                            
(measure 166653/1250 (set (unit 'kg 1) (unit 's -2) (unit 'm -1)))
> millimetre-of-mercury                                           
(measure 166653/1250 (set (unit 'kg 1) (unit 's -2) (unit 'm -1)))
```

By default, all units are converted to SI units. This allows to perform
dimension reductions when possible.

For example:

```racket
> N                                                     
(measure 1 (set (unit 'm 1) (unit 'kg 1) (unit 's -2))) 
> Pa                                                    
(measure 1 (set (unit 'kg 1) (unit 's -2) (unit 'm -1)))
> (m/ (m* 3 N) (m* 2 Pa))                               
(measure 3/2 (set (unit 'm 2)))                         
> (m* 3 mi)                                             
(measure 603504/125 (set (unit 'm 1)))                  
> (m+ (m* 3 mi) (m* 2 m))                               
(measure 603754/125 (set (unit 'm 1)))                  
```

But it is possible to avoid the implicit conversion to SI units by
quoting the short name:

```racket
> (m* 3 'mi)                  
(measure 3 (set (unit 'mi 1)))
```

(Note that quoting is nicely the same as "prevent reduction" to base
units.) Quoted units can be useful in particular in text files from
which to read measures. They can of course be used together:

```racket
> (m+ '(5 mi) (m* 2 '(3 mi)))  
(measure 11 (set (unit 'mi 1)))
```

SI units are actually quoted units:

```racket
> (equal? (m* 3 m (m/ 1 s s))
          (m* '(3 m (s -2))))
#t                           
```

However, now it is not possible to add quantities of different units,
even if they have the same dimension:

```racket
> (m+ (m* 3 'mi) (m* 2 'm))                                
Error: Measures must have the same units.                  
Got: #<set: #(struct:unit m 1)> and #<set: #(struct:unit mi
1)>                                                        
```

Known quoted  units can still be converted back to SI units:

```racket
> (convert* (m* 3 'mi))               
(measure 603504/125 (set (unit 'm 1)))
```

Using the `convert*` function it is also possible to request a
conversion from SI units to non-SI units (or, more precisely,
non-SI-base units):

```racket
> (convert* (m* 3 m)                                   
            'mile)                                     
(measure 125/67056 (set (unit 'mi 1)))                 
> (convert* (m* 3 ft (m/ s))                           
            '(mi (h -1)))                              
(measure 45/22 (set (unit 'mi 1) (unit 'h -1)))        
> (convert* (m* 10 hecto Pa) 'mmHg)                    
(measure 1250000/166653 (set (unit 'mmHg 1)))          
> (m* 2 Pa 3 m m)                                      
(measure 6 (set (unit 'm 1) (unit 'kg 1) (unit 's -2)))
> (convert* (m* 2 Pa 3 m m) 'N)                        
(measure 6 (set (unit 'N 1)))                          
```

It can also be used to convert to unit prefixes:

```racket
> (measure->value (convert* (m* 3 kilo Pa) '(hecto Pa)))
'(30 Pa h.)                                             
```

Notes:

* Prefixes are followed by a dot to avoid name collision with units.

* The order of "units" is first by exponent then alphabetical (ASCII),
  this is why the `h.` is after `Pa`.

The `convert*` function accepts a measure and either:

* the `'SI` symbol (default), to convert to SI units,

* a DSL unit,

* a list of symbols and DSL units.

It can then be used to convert quoted units to SI units and back to
quoted units. For example, this is not what we want (although it is
correct):

```racket
> (convert* (m* 3 'mi) 'yd)                                    
(measure 1250/381 (set (unit 'yd 1) (unit 'mi 1) (unit 'm -1)))
```

This is what we want:

```racket
> (convert* (m* 3 'mi) '(SI yd)) 
(measure 5280 (set (unit 'yd 1)))
```

But of course, without quoted units, we could have written:

```racket
> (convert* (m* 3 mi) 'yd)       
(measure 5280 (set (unit 'yd 1)))
```

# 2. Related resources

Some [useful
conversions](http://en.wikipedia.org/wiki/SI\_derived\_unit) can be
found on Wikipedia (to be trusted with caution of course).

This collection was partly inspired by [the Frink programming
language](http://futureboy.us/frinkdocs/) and Konrad Hinsen’s [Clojure
units library](http://code.google.com/p/clj-units/).

You may also be interested in [Doug Williams scientific
collection](http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html).
