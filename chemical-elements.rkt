#lang racket/base

(require "measure.rkt"
         "default-units.rkt"
         "private/fetch-parse-elements.rkt"
         racket/file
         racket/contract
         (for-syntax racket/base))

; Also provides all the procedures of define-values/provide below
(provide elements find-element)

; The table of elements has been parsed from Wikipedia.
; There is no guarantee on the correctness of the values.
; Also please read the explanations about some of the values:
; http://en.wikipedia.org/wiki/List_of_elements

(define-syntax-rule (define-values/provide (val ...) expr)
  (begin
    (define-values (val ...) expr)
    (provide val) ...))

(define nb-fields 12)
(define-values/provide
  (atomic-number atomic-symbol chemical-element group period
                 atomic-weight density melting-point boiling-point
                 heat-capacity electronegativity
                 abundance)
  (apply values 
         (build-list nb-fields 
                     (λ(n)(λ(x)(if (element? x)
                                   (vector-ref x n)
                                   (let ([e (find-element x)])
                                     (if e
                                         (vector-ref e n)
                                         (error "Element not found:" x)))))))))

(define elt-units (list 1 1 1 1 1 atomic-mass-unit g/cm3 K K (m/ J g) 1 (m/ mg kg)))

(define element? vector?)

(define elements
  (for/vector ([e (get-elements)])
    (apply 
     vector #;element
     (for/list ([v e] [u elt-units])
       (if (or (not (number? v)) (equal? 1 u))
           v
           (m* v u))))))

;; Takes either an atomic number, an atomic symbol or a chemical element name
;; and returns the corresponding element
(define/contract (find-element num/sym/elt)
  ((or/c exact-nonnegative-integer? number? symbol?) . -> . (or/c #f element?))
  (if (number? num/sym/elt)
      (vector-ref elements (sub1 num/sym/elt))
      (for/or ([e elements])
        (and (or (equal? num/sym/elt (atomic-symbol e))
                 (equal? num/sym/elt (chemical-element e)))
             e))))

(module+ test
  (require rackunit)
  
  (check-equal? (vector-length elements) 118)
  (check-true (for/and ([e elements])
                (= (vector-length e) nb-fields)))
  
  (check-equal? (atomic-symbol 'H) 'H)
  (check-equal? (atomic-symbol 'Hydrogen) 'H)
  (check-equal? (atomic-symbol 1) 'H)
  
  (check-equal? (atomic-number 'O) 8)
  (check-equal? (atomic-number 'Oxygen) 8)
  (check-equal? (atomic-number 8) 8)
  
  (check-equal? (chemical-element 'Uuo) 'Ununoctium)
  (check-equal? (chemical-element 'Ununoctium) 'Ununoctium)
  (check-equal? (chemical-element 118) 'Ununoctium)
  )
  
  #|
  (require (only-in racket/list take))
  (define (elt-sort key [n 10])
    (map
     (λ(e)(list (chemical-element e) (key e)))
     (take (sort (vector->list elements) m>
                 #:key (λ(e)(define a (key e))
                         (cond [(number? a) a]
                               [(measure? a)
                                (measure-quantity a)]
                               [else 0])))
           n)))
  ; What are the 10 most abundant elements?
  (elt-sort abundance)
  ; The densest elements?
  (elt-sort density)|#
  

