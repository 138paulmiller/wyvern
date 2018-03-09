(declare (unit analyze))
(require-extension matchable)
(use srfi-1) ;assoc

;Provides semantic analysis


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get-free-vars
;---------------------------------------------------------------------------------------------;
; Counts the number of free-variables in a lambda expression.
;	To do this, count all symbols seen, and at a lambda get the set-difference between the 
;	formals and the symbols seen 
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		list of free vars 		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (get-free-vars root)
	(if (pair? root)
		(if  (eq? 'lambda (car root) )
			;(lambda (formals) body ) free-vars - formals
			(lset-difference eqv? (get-free-vars (cddr root)) (cadr root)  )
			(lset-union eqv? (get-free-vars (car root)) (get-free-vars (cdr root))))
		;if symbol is found
		(if (symbol? root)
			(list root)
			`())))




