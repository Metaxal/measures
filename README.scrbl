#lang scribble/manual

@; compile with @racket[scribble --markdown this-file.scrbl]

@(require scribble/eval
          (for-label racket/base racket/contract racket/string))
@(define my-eval (make-base-eval))
@(my-eval '(require racket/base racket/contract measures))

@title{Units and Measurements}

Units and measurements in Racket, with conversion facilities between units.

First some @bold{warnings}:
@itemize[
@item{This collection has not been extensively tested. Use with caution and please 
      @hyperlink["https://github.com/Metaxal/measures/issues" "report any error that you find"].}
@item{Be cautious with non-linear converters (e.g., °F to K), as converting a temperature difference
      is not the same as converting a temperature.}
]

@section{Quick example}

Say you are traveling at 50 miles per hour:
@interaction[#:eval my-eval
(define my-speed (m* 50. mile (m/ hour)))
(measure->value my-speed)
]
How many kilometers/hour is that?
@interaction[#:eval my-eval
(measure->value (convert* my-speed '(km (h -1))))
]
How many kilometers do you travel during 5 minutes?
@interaction[#:eval my-eval
(measure->value (convert* (m* my-speed 5 min) 'km))
]
You are quite late and have only 13 minutes left before your meeting, and you are 21 miles away.
How fast would you need to go to be there in time?
@interaction[#:eval my-eval
(measure->value (convert* (m/ (m* 21. mi) (m* 13 min)) '(mi (h -1))))
]

@section{Basic definitions}

A @racket[unit] is a symbol and an exponent.
A @racket[measure] is a number and a set of units.

Basic arithmetic operations (@racket[m+] @racket[m-] @racket[m*] @racket[m/] @racket[m^]) are defined
to work with measures.

To ease human interaction, measures can be written in an simple Domain Specific Language (DSL).
A DSL measure can then be:
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

@interaction[#:eval my-eval
(m* 3)
(m* 3 's)
(m* 3 's '(m -1))
]
The arithmetic operators automatically convert DSL measures into @racket[measures]:
@interaction[#:eval my-eval
(m+ 2 3)
(m/ 3 '(2 s))
]
Measures can be turned back to human readable values with @racket[measure->value]:
@interaction[#:eval my-eval
(measure->value (m* '(3 s) 5 '(10 m)))
(measure->value (m* '(3 s) '(5 (s -1))))
]


Adding or subtracting measures with different units raises an @racket[exn:fail:unit] exception:
@interaction[#:eval my-eval
(measure->value (m+ '(3 m (h -1)) '(2 m h)))

(measure->value (m+ '(3 m (h -1)) '(2 m (h -1))))
]


@section{Units and conversions}

All units have a short and a long name.
The short name is the standard symbol, and the long name is more descriptive:
@interaction[#:eval my-eval
mmHg
millimetre-of-mercury
]

By default, all units are converted to SI units.
This allows to perform dimension reductions when possible.

For example:
@interaction[#:eval my-eval
N
Pa
(m/ (m* 3 N) (m* 2 Pa))
(m* 3 mi)
(m+ (m* 3 mi) (m* 2 m))
]

But it is possible to avoid the implicit conversion to SI units by quoting the short name:
@interaction[#:eval my-eval
(m* 3 'mi)
]
(Note that quoting is nicely the same as "prevent reduction" to base units.)
Quoted units can be useful in particular in text files from which to read measures.
They can of course be used together:
@interaction[#:eval my-eval
(m+ '(5 mi) (m* 2 '(3 mi)))
]

SI units are actually quoted units:
@interaction[#:eval my-eval
(equal? (m* 3 m (m/ 1 s s))
        (m* '(3 m (s -2))))
]

However, now it is not possible to add quantities of different units, even if they have the same
dimension:
@interaction[#:eval my-eval
(m+ (m* 3 'mi) (m* 2 'm))
]
Known quoted  units can still be converted back to SI units:
@interaction[#:eval my-eval
(convert* (m* 3 'mi))
]

Using the @racket[convert*] function it is also possible to request a conversion from SI units
to non-SI units (or, more precisely, non-SI-base units):
@interaction[#:eval my-eval
(convert* (m* 3 m)
          'mile)
(convert* (m* 3 ft (m/ s))
          '(mi (h -1)))
(convert* (m* 10 hecto Pa) 'mmHg)
(m* 2 Pa 3 m m)
(convert* (m* 2 Pa 3 m m) 'N)
]

It can also be used to convert to unit prefixes:
@interaction[#:eval my-eval
(measure->value (convert* (m* 3 kilo Pa) '(hecto Pa)))
]
Notes:
@itemize[
@item{Prefixes are followed by a dot to avoid name collision with units.}
@item{The order of "units" is first by exponent then alphabetical (ASCII), this is why the 
      @racket[h.] is after @racket[Pa].}
]

The @racket[convert*] function accepts a measure and either:
@itemize[
@item{the @racket['base] symbol (default), to convert to base (SI by default) units,}
@item{a DSL unit,}
@item{a list of symbols and DSL units.}
]

It can then be used to convert quoted units to SI units and back to quoted units.
For example, this is not what we want (although it is correct):
@interaction[#:eval my-eval
(convert* (m* 3 'mi) 'yd)
]
This is what we want:
@interaction[#:eval my-eval
(convert* (m* 3 'mi) '(base yd))
]
But of course, without quoted units, we could have written:
@interaction[#:eval my-eval
(convert* (m* 3 mi) 'yd)
]

@section{Dimensions and contracts}

Units and measures are organized in dimensions.

For example:
@racketblock[
(define-dimension time (s second)
  ....
  (d    day     86400)
  (min  minute  60)
  (y    year    (m* #e356.25 day))
  )]
This defines a @racket[time] dimension, 
a base unit @racket[s] with a long name @racket[second], 
and several derived units, where a single number expresses a ratio with respect to the base unit,
and an expression denotes a value to be used in place of a ratio.

This also defines the @racket[time/c] contract that can be used in function contracts:
@interaction[ #:eval my-eval
(define/contract (speed a-distance a-time)
  (length/c time/c . -> . velocity/c)
  (m/ a-distance a-time))
(speed (m* 5 mile) (m* 2 hour))
(speed (m* 5 mile) (m* 2 metre))]


@section{Related resources}

Some
@hyperlink["http://en.wikipedia.org/wiki/Conversion_of_units"
           "useful conversions"]
can be found on Wikipedia (to be trusted with caution of course).

This collection was partly inspired by 
@hyperlink["http://futureboy.us/frinkdocs/" "the Frink programming language"]
and Konrad Hinsen's @hyperlink["http://code.google.com/p/clj-units/" "Clojure units library"].

You may also be interested in
@hyperlink["http://planet.racket-lang.org/package-source/williams/science.plt/4/2/planet-docs/science/physical-constants.html"
           "Doug Williams scientific collection"].

@section{License and Disclaimer}

Copyright (c) 2013 Laurent Orseau

Licensed under the GNU LGPL. See LICENSE.

@verbatim{
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
