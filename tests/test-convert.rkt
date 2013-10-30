#lang racket

(require "../measure.rkt"
         "../convert.rkt"
         "../default-units.rkt"
         rackunit)
  
(define (check-measure=? m1 m2 [epsilon 0.])
  (check measure-units-equal? m1 m2)
  (check-= (measure-quantity m1)
           (measure-quantity m2)
           epsilon))

(check-measure=? (convert* (m* 3 newton 2 pascal) '(N Pa))
                 (m* 6 'N 'Pa))

(check-measure=? (convert* (m+ (m* 3 N) (m* 10 Pa 2 m m)) 'N)
                 (m* 23 'N))

(check-measure=? (convert* (m* 10 mi (m/ h)) '(mi (h -1)))
                 (m* 10 'mi '(h -1)))

(check-measure=? (convert* (m* 2 torr 4 m m) 'N)
                 (m* 20265/19 'N))

(check-measure=? (convert* (m* 4 dL) 'L)
                 (m* 2/5 'L))

(check-measure=? (convert* (m* 3000 Pa) '(hecto Pa))
                 (m* 30 'Pa 'h.))

(check-measure=? (convert* (m* 3 kilo Pa) '(hecto Pa))
                 (m* 30 'Pa 'h.))

(define/contract (speed a-distance a-time)
  (length/c time/c . -> . velocity/c)
  (m/ a-distance a-time))
(check-not-exn (λ()(speed (m* 5 mile) (m* 2 hour))))
(check-exn exn:fail:contract? (λ()(speed (m* 5 mile) (m* 2 metre))))
