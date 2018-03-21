(define (a b  c)
	(if (> b c) 
		(display b) 
		(display c))) 


(define (tail_call)
	(a 3 ( + 8 8 ))
	(a 30 ( + 8 8 ))
	(tail_call)
)

(tail_call)

