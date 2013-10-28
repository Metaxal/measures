#lang scribble/manual

@; compile with @racket[scribble --markdown this-file.scrbl]

@(require scribble/eval
          (for-label racket/base racket/contract racket/string))
@(define my-eval (make-base-eval))
@(my-eval '(require racket/base measures))

@section{Units and Measurements}

Units and measurements in Racket.

First some @bold{warnings}:
@itemize[
@item{This collection has not been extensively tested. Use with caution and please report any error that you find at: https://github.com/Metaxal/measures/issues}
@item{Be cautious with non-linear converters (e.g., °F to K), as converting a temperature difference is not the same as converting a temperature.}
]

@subsection{Basic definitions}

A @racket[unit] is a symbol and an exponent.
A @racket[measure] is a number and a set of units.

Basic arithmetic operations (@racket[m+] @racket[m-] @racket[m*] @racket[m/] @racket[m^]) are defined to work with measures.

To ease human interaction, measures can be written in an simple Domain Specific Language (DSL). A DSL measure can then be:
@itemize[
@item{a (struct) measure,}
@item{a number,}
@item{a DSL unit,}
@item{a list with a number followed by one or more DSL units.}
]

A DSL unit can be:
@itemize[
@item{a (struct) unit,}
@item{a symbol alone (taking the exponent 1 by default),}
@item{a list with a symbol and an exponent.}
]

You can use the multiplication operator @racket[m*] to easily build measures.

Example:
@examples[#:eval my-eval
(m* 3)
(m* 3 's)
(m* 3 's '(m -1))
]
The arithmetic operators automatically convert DSL measures into @racket[measures]:
@examples[#:eval my-eval
(m+ 2 3)
(m/ 3 '(2 s))
]
Measures can be turned back to human readable values with @racket[measure->value]:
@examples[#:eval my-eval
(measure->value (m* '(3 s) 5 '(10 m)))
(measure->value (m* '(3 s) '(5 (s -1))))
]


Adding or subtracting measures with different units raises an @racket[exn:fail:unit] exception:
@examples[#:eval my-eval
(measure->value (m+ '(3 m (h -1)) '(2 m h)))

(measure->value (m+ '(3 m (h -1)) '(2 m (h -1))))
]


@subsection{Units and conversions}

All units have a short and a long name.
The short name is the standard symbol, and the long name is more descriptive:
@examples[#:eval my-eval
mmHg
millimetre-of-mercury
]

By default, all units are converted to SI units.
This allows to perform dimension reductions when possible.

For example:
@examples[#:eval my-eval
N
Pa
(m/ (m* 3 N) (m* 2 Pa))
(m* 3 mi)
(m+ (m* 3 mi) (m* 2 m))
]

But it is possible to avoid the implicit conversion to SI units by quoting the short name:
@examples[#:eval my-eval
(m* 3 'mi)
]
(Note that quoting is nicely the same as "prevent reduction" to base units.)
Quoted units can be useful in particular in text files from which to read measures.
They can of course be used together:
@examples[#:eval my-eval
(m+ '(5 mi) (m* 2 '(3 mi)))
]

SI units are actually quoted units:
@examples[#:eval my-eval
(equal? (m* 3 m (m/ 1 s s))
        (m* '(3 m (s -2))))
]

However, now it is not possible to add quantities of different units, even if they have the same dimension:
@examples[#:eval my-eval
(m+ (m* 3 'mi) (m* 2 'm))
]
Known quoted  units can still be converted back to SI units:
@examples[#:eval my-eval
(convert* (m* 3 'mi))
]

Using the @racket[convert*] function it is also possible to request a conversion from SI units to non-SI units (or, more precisely, non-SI-base units):
@examples[#:eval my-eval
(convert* (m* 3 m)
          'mile)
(convert* (m* 3 ft (m/ s))
          '(mi (h -1)))
(convert* (m* 10 hecto Pa) 'mmHg)
(m* 2 Pa 3 m m)
(convert* (m* 2 Pa 3 m m) 'N)
]

It can also be used to convert to unit prefixes:
@examples[#:eval my-eval
(measure->value (convert* (m* 3 kilo Pa) '(hecto Pa)))
]
Notes:
@itemize[
@item{Prefixes are followed by a dot to avoid name collision with units.}
@item{The order of "units" is first by exponent then alphabetical (ASCII), this is why the @racket[h.] is after @racket[Pa].}
]

The @racket[convert*] function accepts a measure and either:
@itemize[
@item{the @racket['SI] symbol (default), to convert to SI units}
@item{a DSL unit,}
@item{a list of symbols and DSL units.}
]

It can then be used to convert quoted units to SI units and back to quoted units.
For example, this is not what we want (although it is correct):
@examples[#:eval my-eval
(convert* (m* 3 'mi) 'yd)
]
This is what we want:
@examples[#:eval my-eval
(convert* (m* 3 'mi) '(SI yd))
]

@section{Related resources}

Some
@hyperlink["http://en.wikipedia.org/wiki/SI_derived_unit"
           "useful conversions"]
can be found on Wikipedia (to be trusted with caution of course).

@hyperlink["http://futureboy.us/frinkdocs/" "The Frink programming language."]

You may also be interested in
@hyperlink["http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html"
           "Doug Williams scientific collection"].


