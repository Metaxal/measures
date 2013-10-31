#lang at-exp racket
(require net/http-client
         racket/date
         racket/runtime-path)

(provide get-elements)

;; If the elements.rktd file needs to be regenerated from Wikipedia,
;; first make a copy of the file,
;; then call `(fetch-elements)' and `(parse-elements)'. 
;; Make sure that the parsing worked by running the tests in "chemical-elements.rkt",
;; and maybe take a look at the new file yourself (the table is aligned)
;; or call `(get-elements)'.
;; That's all. Now `(require measures/chemical-elements)' will work on the updated values.

(define-runtime-path elements-txt-file "elements.txt")
(define-runtime-path elements-rktd-file "elements.rktd")

;; Fetchs the element list for Wikipedia, keep only the lines with elements
;; and write it to elements-file.
;; Avoids querying wikipedia several times in case the parser needs to be changed.
(define (fetch-elements)
  (define-values (status headers in)
    (http-sendrecv 
     "en.wikipedia.org"
     "http://en.wikipedia.org/w/index.php?title=List_of_elements&action=edit&section=1"))
  (with-output-to-file elements-txt-file #:exists 'replace
    (λ()
      (printf "Fetched on: ~a\n" 
              (parameterize ([date-display-format 'iso-8601])
                (date->string (current-date) #t)))
      (for/list ([line (port->lines in)])
        (when (regexp-match @px{^\| \d} line)
          (displayln line)))))
  (close-input-port in))

(define px pregexp)

;; Reads the element-file and turns it into a vector of elements
(define (parse-elements)
  (define in (open-input-file elements-txt-file))
  (define elements-raw
    (for/list ([line (port->lines in)]
               #:when (regexp-match @px{^\| \d} line))
      (string-split
       (regexp-replaces 
        line
        `([, #px"\\{\\{ref[^\\}]*\\}\\}" ""]
          [, @px{style[^\|]*\| } ""]
          ; {{sort|1234.435(3)|1234}}
          [, #px"\\{\\{sort\\|[^\\|]*\\|([^}]*)\\}\\}" "\\1"]
          ; remove trailing | and trim spaces
          [, #px"^\\|\\s*(.*\\S)\\s*$" "\\1"]
          [, #rx"–" "#f"]
          [, @px{\[\[([^\|\]]*\|)?([^\]]*)\]\]} "\\2"]
          ; remove precision, e.g. 123.234(4)
          [, @px{(\d+)\(\d*\)} "\\1"]
          ; promote uncertain values to numbers
          [, @px{(?:\(|\[)?([\.0-9]*)(?:\)|\])?} "\\1"]
          [, #px"&lt;" "<"]
          )) 
       @px{\s*\|\|\s*})))
  (define elements-no-txt
    (map (λ(e)(let-values ([(a b) (split-at e 3)])
                (append a (rest b))))
         elements-raw))
  (define max-cols
    (for/list ([col (apply map list elements-no-txt)])
      (apply max (map string-length col))))
  (with-output-to-file elements-rktd-file #:exists 'replace
    (λ()(for ([elt elements-no-txt])
          (display "(")
          (for ([v elt] [len max-cols])
            (display (~a (if (equal? v "") "#f" v) #:min-width (add1 len))))
          (displayln ")")))))

(define (get-elements)
  (file->list elements-rktd-file))
