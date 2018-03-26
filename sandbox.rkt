(module sandbox racket
  (provide
    import-action-sequences
    save-action-seq!
    (struct-out action)
    (struct-out action-seq))


  (require racket/file)
  (require csv-reading)

  (struct action (name)
    #:methods gen:custom-write
    [(define (write-proc action port mode)
      (fprintf port "~a" (action-name action)))])

  (define (action->string action) (format "~a" action))

  (struct action-seq (name actions)
    #:methods gen:custom-write
    [(define (write-proc action-seq port mode)
      (fprintf port "~a" (string-join (map action->string (action-seq-actions action-seq))
        #:before-first (format "<~a:(" (action-seq-name action-seq))
        #:after-last ")>")))])

  (define action-seq-db "./action-sequences.csv")
  (define make-db-reader
    (begin
      ; Ensure the file exists by creating an empty one if it doesn't.
      (display-lines-to-file '() action-seq-db #:exists 'append)
      (make-csv-reader-maker
        '((separator-chars #\,))) ))
  (define next-action-seq! (make-db-reader (open-input-file action-seq-db)))
  (define (import-action-sequences)
    (csv-map (lambda (row)
                (action-seq
                  (string->symbol (first row))
                  (map (lambda (action-id) (action (string->symbol action-id))) (string-split (second row) ","))))
              next-action-seq!))

  (define (save-action-seq! seq)
    (let ([action-seq (format "~a,~a~n" (action-seq-name seq) (string-join (map action->string (action-seq-actions seq)) " " #:before-first "\"" #:after-last "\""))])
      (display-to-file action-seq action-seq-db #:exists 'append)))
); end module sandbox

(require 'sandbox)

(define app-switch (action 'app-switch))
(define mouse-click (action 'mouse-click))
(define new-line (action 'new-line))
(define input-entered (action-seq 'input-entered (list mouse-click new-line)))

; Save an action sequence to the DB.
(save-action-seq! input-entered)
; Read it back out.
(define (load-action-sequences) (make-hash (map (lambda (seq) `(,(action-seq-name seq) ,seq)) (import-action-sequences))))
(define action-sequences
  (let ([db (make-hash)])
    (hash-set! db 'seqs (load-action-sequences))
    (lambda (#:reload [reload #f])
      (cond
        [reload (hash-set! db 'seqs (load-action-sequences))]
        [else (hash-ref db 'seqs)]))))

(hash-ref (action-sequences) (action-seq-name input-entered))
