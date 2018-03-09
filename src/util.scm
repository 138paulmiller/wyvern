
(declare (unit util))

(define line 0) 
(define target #f) 
(define is-repl #f) 

(define (port-line port) 
	(let-values (((line _) (port-position port)))
	 	line))
  
(define (port-column port)
    (let-values (((_ column) (port-position port)))
		column))

(define (make-reader ) 
	(let* 
		((args (command-line-arguments))
		(is_mode (and (pair? args) (set! target (car args))))
		(try_file (and is_mode (pair? (cdr args))))
		(port 
			(if try_file
				(open-input-file (cadr args))
				(current-input-port))))
		(set! is-repl try_file)
		(lambda ()
				(if (not try_file)
							(display ""))
					(begin 
						(set! line (port-line port))
						(read port)))))

