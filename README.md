# Units and Measurements

Units and measurements in Racket, with conversion facilities between
units.

First some **warnings**:

* This collection has not been extensively tested. Use with caution and
  please [report any error that you
  find](https://github.com/Metaxal/measures/issues).

* Be cautious with non-linear converters (e.g., °F to K), as converting
  a temperature difference is not the same as converting a temperature.

* Some bindings from `racket` may be redefined, like `second`, `min` and
  `drop`. You can use `rename-in` to change these name on `require`.

## 1. Quick example

Say you are traveling at 50 miles per hour:

```racket
> (define my-speed (m* 50.0 mile (m/ hour)))
                                            
> (measure->value my-speed)                 
'(22.352 m (s -1))                          
```

How many kilometers/hour is that?

```racket
> (measure->value (convert my-speed '(km (h -1))))
'(80.46719999999999 km (h -1))                    
```

How many kilometers do you travel during 5 minutes?

```racket
> (measure->value (convert (m* my-speed 5 min) 'km))
'(6.7056000000000004 km)                            
```

You are quite late and have only 13 minutes left before your meeting,
and you are 21 miles away. How fast would you need to go to be there in
time?

```racket
> (measure->value (convert (m/ (m* 21.0 mi) (m* 13 min)) '(mi (h -1))))
'(96.9230769230769 mi (h -1))                                          
```

## 2. Basic definitions

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

## 3. Units and conversions

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
> (convert (m* 3 'mi))                
(measure 603504/125 (set (unit 'm 1)))
```

Using the `convert` function it is also possible to request a conversion
from SI units to non-SI units (or, more precisely, non-SI-base units):

```racket
> (convert (m* 3 m)                                    
            'mile)                                     
(measure 125/67056 (set (unit 'mi 1)))                 
> (convert (m* 3 ft (m/ s))                            
            '(mi (h -1)))                              
(measure 45/22 (set (unit 'mi 1) (unit 'h -1)))        
> (convert (m* 10 hecto Pa) 'mmHg)                     
(measure 1250000/166653 (set (unit 'mmHg 1)))          
> (m* 2 Pa 3 m m)                                      
(measure 6 (set (unit 'm 1) (unit 'kg 1) (unit 's -2)))
> (convert (m* 2 Pa 3 m m) 'N)                         
(measure 6 (set (unit 'N 1)))                          
```

It can also be used to convert to unit prefixes:

```racket
> (measure->value (convert (m* 3 kilo Pa) '(hecto Pa)))
'(30 Pa h.)                                            
```

Notes:

* Prefixes are followed by a dot to avoid name collision with units.

* The order of "units" is first by exponent then alphabetical (ASCII),
  this is why the `h.` is after `Pa`.

The `convert` function accepts a measure and either:

* the `'base` symbol (default), to convert to base (SI by default)
  units,

* a DSL unit,

* a list of symbols and DSL units.

It can then be used to convert quoted units to SI units and back to
quoted units. For example, this is not what we want (although it is
correct):

```racket
> (convert (m* 3 'mi) 'yd)                                     
(measure 1250/381 (set (unit 'mi 1) (unit 'yd 1) (unit 'm -1)))
```

This is what we want:

```racket
> (convert (m* 3 'mi) '(base yd))
(measure 5280 (set (unit 'yd 1)))
```

But of course, without quoted units, we could have written:

```racket
> (convert (m* 3 mi) 'yd)        
(measure 5280 (set (unit 'yd 1)))
```

## 4. Dimensions and contracts

Units and measures are organized in dimensions.

For example:

```racket
(define-dimension time (s second)
  ....                           
  (d    day     86400)           
  (min  minute  60)              
  (y    year    (m* 1425/4 day)))
```

This defines a `time` dimension, a base unit `s` with a long name
`second`, and several derived units, where a single number expresses a
ratio with respect to the base unit, and an expression denotes a value
to be used in place of a ratio.

This also defines the `time/c` contract that can be used in function
contracts:

```racket
> (define/contract (speed a-distance a-time)      
    (length/c time/c . -> . velocity/c)           
    (m/ a-distance a-time))                       
                                                  
> (speed (m* 5 mile) (m* 2 hour))                 
(measure 1397/1250 (set (unit 'm 1) (unit 's -1)))
> (speed (m* 5 mile) (m* 2 metre))                
speed: contract violation                         
  expected: time/c                                
  given: (measure 2 (set (unit 'm 1)))            
  in: the 2nd argument of                         
      (-> length/c time/c velocity/c)             
  contract from: (function speed)                 
  blaming: top-level                              
  at: eval:37.0                                   
```

## 5. A ’measures’ language

The `measures/lang` language can be used as a short-hand to have all of
`racket` plus all of of `measures` except that the measures arithmetic
operators (`m+`, etc.) replace the normal ones (`+`, etc.).

As a consequence, one can write:

```racket
#lang s-exp measures/lang
                         
(+ (* 5 mi) (* 5 km))    
```

This is also useful to be used in a terminal by invoking:

```racket
racket -li measures/lang
```

This opens an interaction session where `measures/lang` is loaded.

## 6. Chemical elements

The `measures/chemical-elements` provides the vector `elements` of the
118 elements with a number of procedures to extract their information:
`atomic-number` `atomic-symbol` `chemical-element` `group` `period`
`atomic-weight` `density` `melting-point` `boiling-point`
`heat-capacity` `electronegativity` `abundance`.

Each procedure accepts either a number (the atomic number) or a symbol
(either the atomic symbol or the name of the chemical element).

```racket
Examples:                                       
> (require measures/chemical-elements)          
                                                
> (atomic-number 'Oxygen)                       
8                                               
> (atomic-symbol 'Iron)                         
'Fe                                             
> (atomic-symbol 2)                             
'He                                             
> (chemical-element 'Na)                        
'Sodium                                         
> (atomic-weight 'Carbon)                       
(measure 1.99447483422e-26 (set (unit 'kg 1)))  
> (m* 3 cl (density 'Mercury))                  
(measure 0.40600800000000004 (set (unit 'kg 1)))
```

## 7. Related resources

Some [useful
conversions](http://en.wikipedia.org/wiki/Conversion\_of\_units) can be
found on Wikipedia (to be trusted with caution of course).

This collection was partly inspired by [the Frink programming
language](http://futureboy.us/frinkdocs/) and Konrad Hinsen’s [Clojure
units library](http://code.google.com/p/clj-units/).

You may also be interested in [Doug Williams scientific
collection](http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html).

## 8. License and Disclaimer

Copyright (c) 2013 Laurent Orseau

Licensed under the GNU LGPL. See LICENSE.

`THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS`   
`“AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT`     
`LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR` 
`A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT`  
`HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,`
`SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT`      
`LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,` 
`DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY` 
`THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT`   
`(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE` 
`OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.`  
