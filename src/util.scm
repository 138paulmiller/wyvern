
(declare (unit util))

(define line 0) 
(define target #f) 
(define is-repl #f) 


(define (get-target)target)

(define (check-target)
	(or (string=? target "-js") (string=? target "-llvm")))


(define (port-line port) 
	(let-values (((line _) (port-position port)))
	 	line))
  
(define (port-column port)
    (let-values (((_ column) (port-position port)))
		column))

(define (make-reader) 
	(let* 
		((args (command-line-arguments))
		(is-mode (and (pair? args) (set! target (car args)) (check-target)   ))
		(try-file (and is-mode (pair? (cdr args))))
		(port 
			(if try-file
				(open-input-file (cadr args))
				(current-input-port))))
		(set! is-repl (and is-mode (not try-file)))
		(lambda ()
				(if (not try-file)
						(display ""))
					(begin 
						(set! line (port-line port))
						(read port)))))

