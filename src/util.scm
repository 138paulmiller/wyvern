
(declare (unit util))

;Procedure to get file
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
					(read port))))


