; Syntax manipulation
; Performs name-mangling, and mutable variable wrapping, free variable analysis and closure conversion
; 	
;	1: Name-mangling : 	Tranlates Scheme symbols into valid LLVM names.
;
;
; 	2: Free Variable : 	Determines the set of free vars in a lambda and
;					   	retranslates the command to get the var from the 
;						env.  This is used in the closure conversion so that 
;						all free vars, are calls to a struct member
;				(lambda (v1 ... ) (... x1 ...)  ) => (lambda (v1 ... ) (... x1 ...)  ) 
;
;	3: Closure Conversion: Convert lambda's into closure allocation 
;
;				(lambda (v1 ... vN) ... x ...) =>
;	 			(closure (lambda ($env v1 ... vN) ... (env-get k x $env) ...)
;         				 (make-env-struct k (x1 x1) ... (xN xN))) => which becomes
;				 	MakeClosure(lambda_k,alloc_env_k(x1,...xN))

;						 struct env_k {
;							// All free variables:
;							Value x ;
;							...
;						} ;
;						
;						struct env_k* alloc_env_k(Value x, ...) {
;							struct env_k* t = malloc(sizeof(struct env_k)) ;
;							t->x = x ;
;							...
;							return t;
;						}

;						Value lambda_k(struct env_k* $env, Value v1, ... Value vN) {
;							...
;							$env->x 
;							...
;						} 
;				To generate a function call
;			 (f arg1 ... argN)
; 				=>
;			 (tmp = [make lambda f],
;			  	tmp.clo.lam(tmp.clo.env,[compile arg1],...,[compile argN]))
;			
;			Create closure pointing to lambda proc, and create env-struct for all free vars for the closure
;
;	4: Mutable Variables  Create Cells that are globally defined
;					
(declare (unit manip))
(use srfi-1)


(define (manip root)
	(if (pair? root)
		(begin
			(if  (eq? 'lambda (car root) )
				;(lambda (formals) body ) 
				(display (get-free-vars root)))

			(append (list  (manip (car root))) 
					( manip(cdr root)))

		)
		root))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; free-vars
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