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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unique-values
;---------------------------------------------------------------------------------------------;
; List of all different length value objects created (__make_value1__ ... __make_valuen__ )
;	Each value object is returned as a temporary parameters titled __value_t1__ ... __value_tm__ 
;	NOTE: value_t (1..m is not length but rather which value object)
;	whose components are accessed with  __get_valuen_i__(__value_t__) which is passed the value object
;	add-unique-value Called during desugaring! 
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		list of values types		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define unique-values '())

(define (add-unique-value valuen)
	(set! unique-values (lset-union eqv? unique-values (list valuen) )))
