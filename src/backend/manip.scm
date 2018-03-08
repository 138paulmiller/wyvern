; Syntax manipulation utilities for LLVM backend
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
;				(lambda (v1 ... vN) ... x ...) =>
;	 			(closure (lambda ($env v1 ... vN) 
;							... (env-get k x $env) ...)
;         				 (make-env-struct k (x1 x1) ... (xN xN))) 
;				To generate a function call
;			 (f arg1 ... argN)
; 				=>
;			 (tmp = [make lambda f],
;			  	tmp.closure.lam(tmp.closure.env,[compile arg1],...,[compile argN]))
;			
;			Create closure pointing to lambda proc, and create env-struct for all free vars for the closure
;
;	4: Mutable Variables  Create Cells that are allocated on the heap for all vars modified with set!
; 			(lambda (... mvar ...) body) 
;           =>
; 			(lambda (... $v ...) 
; 			 (let ((mvar (cell $v)))
;   					body))
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
					( manip(cdr root))))
		root))
