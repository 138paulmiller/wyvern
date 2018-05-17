;program to return the nth fib numbers in a list
; written using as many features as possible

(display 
	(let sum_help ([x 10]) 
	  ((lambda (x)
		(if (= x 0)
			0
			(+ x (sum_help (- x 1))))) x)) 

)
