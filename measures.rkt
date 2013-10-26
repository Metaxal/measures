#lang racket/base

(require racket/contract
         racket/set
         racket/match
         racket/list)

;;; No automatic conversion between measures

;;;
;;; Data structure and basic operations
;;;

(provide (struct-out unit)
         (struct-out exn:fail:unit)
         (struct-out measure)
         unit-equal?
         unit-same?
         measure-units-equal?
         m mzero? m+ m- m* m/
         measure->value
         )

;; symbol : symbol? ; SI symbol
;; expt : number? ; exponent
(struct unit (symbol expt)
  #:transparent)

(struct exn:fail:unit exn:fail ())

;; Same symbol and exponent
(define/contract (unit-equal? u1 u2)
  (unit? unit? . -> . unit?)
  (and (eq? (unit-symbol u1) (unit-symbol u2))
       (= (unit-expt u1) (unit-expt u2))))

;; Same symbol only
(define/contract (unit-same? u1 u2)
  (unit? unit? . -> . boolean?)
  (equal? (unit-symbol u1) (unit-symbol u2)))

;; unit unit -> unit
(define/contract (unit-multiply u1 u2)
  (unit? unit? . -> . unit?)
  (unless (unit-same? u1 u2)
    (raise (exn:fail:unit
            (format "Units are not the same. Got: ~a and ~a" 
                    (unit-symbol u1)
                    (unit-symbol u2))
            (current-continuation-marks))))
  (unit (unit-symbol u1) (+ (unit-expt u1) (unit-expt u2))))

;; units: (setof unit)
(struct measure (quantity units)
  #:transparent)

(define/contract (measure-zero? v)
  (measure? . -> . boolean?)
  (zero? (measure-quantity v)))

(define/contract (measure-units-equal? m1 m2)
  (measure? measure? . -> . boolean?)
  (set=? (measure-units m1)
         (measure-units m2)))

;;;
;;; Binary operations on measures
;;;

;; 
(define/contract (measure-add m1 m2)
  (measure? measure? . -> . measure?)
  (unless (measure-units-equal? m1 m2)
    (raise (exn:fail:unit
            (format "Values must have the same units.\nGot: ~a and ~a"
                    (measure-units m1)
                    (measure-units m2))
            (current-continuation-marks))))
  (measure (+ (measure-quantity m1) (measure-quantity m2))
         (measure-units m1)))

(define/contract (measure-opposite v)
  (measure? . -> . measure?)
  (measure (- (measure-quantity v)) (measure-units v)))

;; Returns a new unit set by multiplying the specified unit with the same unit
;; in the specified set if it exists, or adds the new unit to the set otherwise.
;; If the new unit has exponent 0, it is removed for the set of units.
(define/contract (units-multiply-unit us u)
  ((set/c unit?) unit? . -> . (set/c unit?))
  (define us-init us)
  (let loop ([us us] [us-pre (set)])
    (if (set-empty? us)
        (set-add us-init u)
        (let ([u2 (set-first us)])
          (if (unit-same? u2 u)
              (let ([new-u (unit-multiply u2 u)])
                (if (zero? (unit-expt new-u))
                    (set-union (set-rest us) us-pre)
                    (set-union (set-add (set-rest us) new-u)
                               us-pre)))
              (loop (set-rest us) (set-add us-pre u2)))))))

;; Multiplies the quantities and the units
(define/contract (measure-multiply m1 m2)
  (measure? measure? . -> . measure?)
  (define us
    (for/fold ([us-out (set)]
               )([u (in-sequences (measure-units m1) (measure-units m2))])
      (units-multiply-unit us-out u)))
  (measure (* (measure-quantity m1) (measure-quantity m2))
         us))

;; Inverses the quantity and the units.
(define/contract (measure-inverse v)
  (measure? . -> . measure?)
  (measure (/ (measure-quantity v))
         (set-map (measure-units v) (λ(u)(unit (unit-symbol u) (- (unit-expt u)))))))

(define/contract (measure-divide m1 m2)
  (measure? measure? . -> . measure?)
  (measure-multiply m1 (measure-inverse m2)))

;; Tests

(module+ test
  (require rackunit)
  (define meter (unit 'm 1))
  (define second (unit 's 1))
  (define m1 (measure 4 (set meter)))
  (define m2 (measure 3 (set second)))
  
  (check-equal? (measure-add m1 m1)
                (measure 8 (set (unit 'm 1))))
  
  (check-equal? (measure-multiply m1 m2)
                (measure 12 (set (unit 'm 1) (unit 's 1))))
  
  (check-equal? (measure-multiply m1 (measure-inverse m1))
                (measure 1 (set)))
  
  (check-exn exn:fail:unit?
             (λ()(measure-add m1 m2)))
  )

;;;
;;; Some operations for easier human writing
;;;

(define (->unit arg)
  (match arg
    [(? unit?) arg]
    [(? symbol?) (unit arg 1)]
    [(list (? symbol? s) (? number? n))
     (unit s n)]))

(define (->measure arg)
  (match arg
    [(? measure?) arg]
    [(or (? number? n) (list (? number? n)))
     (measure n (set))]
    [(or (list (? number? n) units ...)
         (list (list (? number? n) units ...)))
     (measure n (list->set (map ->unit units)))]))

(define (m . args) 
  (->measure args))

(define (mzero? x)
  (measure-zero? (->measure x)))

(define (m+ m1 . vl) 
  (foldl measure-add (->measure m1) (map ->measure vl)))

(define m-
  (case-lambda
    [(m1) (measure-opposite (->measure m1))]
    [(m1 . vl)
     (apply m+ m1 (map measure-opposite (map ->measure vl)))]))

(define (m* m1 . vl) 
  ; Todo: optimize if zero?
  (foldl measure-multiply (->measure m1) (map ->measure vl)))

(define m/ 
  (case-lambda
    [(m1) (measure-inverse (->measure m1))]
    [(m1 . vl)
     (apply m* m1 (map measure-inverse (map ->measure vl)))]))

(module+ test
  (check-equal? (m* '(3 s) '(360 m (s -1)))
                (measure 1080 (set (unit 'm 1))))
  
  (check-pred mzero? (m* 0 '(2 m s)))
  
  (check-equal? (m* '(52.8 ft (s -1))
                    (m/ '(1 mi)
                        '(5280 ft))
                    (m/ '(3600 s)
                        '(1 h)))
                (m '(36.0 mi (h -1))))
  
  (check-equal? (m- '(23 s) '(2 s) '(10 s))
                (m '(11 s)))
  )

;;;
;;; Some transformers for easier human reading
;;;

(define/contract (unit->value u)
  (unit? . -> . any/c)
  (if (= 1 (unit-expt u))
      (unit-symbol u)
      (list (unit-symbol u) (unit-expt u))))

(define/contract (measure->value m1)
  (measure? . -> . any/c)
  (define l (sort (set->list (measure-units m1)) 
                  (λ(u1 u2)(or (> (unit-expt u1) (unit-expt u2))
                               (and (= (unit-expt u1) (unit-expt u2))
                                    (symbol<? (unit-symbol u1) (unit-symbol u2)))))))
  (define q (measure-quantity m1))
  (if (empty? l)
      q
      (cons q (map unit->value l))))

(module+ test
  (check-equal?
   (measure->value (m '(4 (N 2) m (s -1))))
   '(4 (N 2) m (s -1)))
  
  (check-equal? (measure->value (m 4)) 
                4)
  
  (check-equal? (measure->value (m '(4 s))) 
                '(4 s))
  )
