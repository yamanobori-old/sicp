; 練習問題35
(define (square a b)
  (define (process-new-value)
    (if (has-value? b)
      (if (< (get-value b) 0)
        (error "square less than 0: SQUARER" (get-value b))
        (set-value! a (sqrt (get-value b)) me))
      (if (has-value? a)
        (set-value! b (* (get-value a) (get-value a)) me))))

  (define (process-forget-value)
    (forget-value! a me)
    (forget-value! b me)
    (process-new-value))

  (define (me request)
    (cond
      ((eq? request 'I-have-a-value) (process-new-value))
      ((eq? request 'I-lost-my-value) (process-forget-value))
      (else (error "Unknown request: SQUARER" request))))
  (connect a me)
  (connect b me)
  me)

(define (has-value? connector) (connector 'has-value?))
(define (get-value connector) (connector 'value))
(define (set-value! connector newval informant) ((connector 'set-value!) newval informant))
(define (forget-value! connector retractor) ((connector 'forget) retractor))
(define (connect connector new-constraint) ((connector 'connect) new-constraint))

(define (make-connector)
  (let ((value #f) (informant #f) (constraints '()))
    (define (set-my-value newval setter)
      (cond
        ((not (has-value? me))
         (set! value newval)
         (set! informant setter)
         (for-each-except setter inform-about-value constraints))
        ((not (= value newval))
         (error "Contradiction" (list value newval)))
        (else 'ignored)))
    (define (forget-my-value retractor)
      (if (eq? retractor informant)
        (begin
          (set! informant #f)
          (for-each-except retractor inform-about-no-value constraints))
        'ignored))
    (define (connect new-constraint)
      (if (not (memq new-constraint constraints))
        (set! constraints (cons new-constraint constraints)))
      (if (has-value? me)
        (inform-about-value new-constraint))
      'done)
    (define (me request)
      (cond
        ((eq? request 'has-value?) (if informant #t #f))
        ((eq? request 'value) value)
        ((eq? request 'set-value!) set-my-value)
        ((eq? request 'forget) forget-my-value)
        ((eq? request 'connect) connect)
        (else (error "Unknown operation: CONNECTOR" request))))
    me))
(define (for-each-except exception procedure lst)
  (define (loop items)
    (cond
      ((null? items) 'done)
      ((eq? (car items) exception) (loop (cdr items)))
      (else (procedure (car items))
            (loop (cdr items)))))
  (loop lst))

(define (probe name connector)
  (define (print-probe value)
    (newline) (display "Probe: ") (display name) (display " = ") (display value))
  (define (process-new-value)
    (print-probe (get-value connector)))
  (define (process-forget-value)
    (print-probe "?"))
  (define (me request)
    (cond
      ((eq? request 'I-have-a-value) (process-new-value))
      ((eq? request 'I-lost-my-value) (process-forget-value))
      (else (error "Unknown request: PROBE" request))))
  (connect connector me)
  me)

; 値を持ったことを伝える
(define (inform-about-value constraint) (constraint 'I-have-a-value))
; 値を失ったことを伝える
(define (inform-about-no-value constraint) (constraint 'I-lost-my-value))

;定数
(define (constant value connector)
  (define (me request)
    (error "Unknown request: CONSTANT" request)) ;requestは受け付けない
  (connect connector me)
  (set-value! connector value me)
  me)

;===============================================================================
; テスト
(define A (make-connector))
(define B (make-connector))
(square A B)
(probe "A=" A)
(probe "B=" B)

(set-value! A 2.0 'me)
(forget-value! A 'me)
(forget-value! B 'me)

(set-value! B 3.0 'me)
(forget-value! A 'me)
(forget-value! B 'me)

(get-value B)
(get-value A)
(set-value! A 7.0 'me)
(forget-value! C 'me)
(set-value! C 13.0 'me)
