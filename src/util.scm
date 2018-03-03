
(declare (unit util))

(define line 0) 

(define (port-line port) 
	(let-values (((line _) (port-position port)))
	 	line))
  
(define (port-column port)
    (let-values (((_ column) (port-position port)))
		column))

(define (make-reader ) 
	(let* 
		((args (command-line-arguments))
		(try_file (pair? args))
		(port 
		(if try_file
			(open-input-file 
				(if (pair? (cdr args))
					(cadr args)
					(car args)))
			(current-input-port))))
		(lambda ()
				(if (not try_file)
							(display ""))
					(begin 
						(set! line (port-line port))
						(read port)))))

