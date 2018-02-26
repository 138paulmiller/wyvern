(declare (unit desugar))

(require-extension matchable)
(require-extension r7rs)
(define (syntax-error msg)
 	(call/cc (lambda (e)
 			(display msg)
 		)))

(define (desugar root)
	(desugar-letrec*
	(desugar-letrec
	(desugar-cond 
	(desugar-let* 
	(desugar-let 
	(desugar-brackets
	(desugar-quote-strings
		root

	)	
	)
	)
	)
	)
	)
	)
)
; condition			x
; quasiquotation 
; case			
; and 
; or  
; when 
; unless 
; let     			x
; let*    			x
; letrec  			x
; letrec*  			x
; let-values  
; let*-values 
; begin  
; do  
; delay 
; delay-force 
; parameterize  
; guard  
; case-lambda


;brackets
; [expr...] ==> (expr ... )
(define (desugar-brackets root)	
	(let ( (node 
			(match root    
				( ( [ expr ... ] )  
					`(,expr))
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-brackets (car node))) (desugar-brackets (cdr node)))
			node)))

; strings - any string objects read by (read) will be wrapped with quotes
;wrap any strings with quotes
(define (desugar-quote-strings root)	
	(let ( (node 
			(if (string? root)
						(string-append "\""  root "\"")
						root)))
			(if (pair? node)
				(append (list (desugar-quote-strings (car node))) (desugar-quote-strings (cdr node)))
			node)))

;condition 
;	(cond (test expr) ... (testN exprN) (else expr ) )
;		 ==> (if  test 
;				then 
;				(cond ... (testN exprN) (else expr ) )
(define (desugar-cond root)	
	(let ( (node 
			(match root    
				( ( 'cond clause ... (testN exprN) )  
					;if test and expr are null the single condition in testN and exprN
					;if testN == else the return expr, else return (if testN exprN)  
					(if (and (null? clause))
						(if (eq? 'else testN) 
							(desugar-cond exprN)
							`(if ,(desugar-cond testN) ,(desugar-cond exprN) '() ))
						`(if ,(desugar-cond (caar clause ))
							,(desugar-cond (cadar clause ))
						 ,(desugar-cond  `(cond ,@`(,@(cdr clause) ,`(,testN ,exprN) ))))))
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-cond (car node))) (desugar-cond (cdr node)))
			node)))

;let
; (let ((var expr) ... (varN exprN)) body )
;	==> ((lambda (var... varN ) body  ) expr ... exprN)
; Tagged let
; (let tag ((vars exprs) ...) body ...)
; ==> ((letrec ( 
; 			(tag (lambda (vars )
; 						body )))
; 		tag)
; 			exprs ...)
(define (desugar-let root)	
	(let ( (node 
			(match root    
				( ( 'let ( (vars exprs) ...  ) body ... )  
					;ensure that vars are all symbols?
					`((lambda ,vars ,@body ) ,@exprs))
				;tagged let
				( ( 'let tag ( (vars exprs) ... ) body ... )
					(desugar-letrec `((letrec 
								;bind tag to lambda that takes all vars 
								((,tag (lambda ,vars 
											,@body )))
										,tag)
								,@exprs))
				)
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-let (car node))) 
						(desugar-let (cdr node)))
			node)))


;let*
; (let* ((var expr) ... (varN exprN)) body )
;	==> ((lambda (var ) 
;			(let* (... varN ) 
;					body )  ... exprN ) expr)
(define (desugar-let* root)	
	(let ( (node 
			(match root    
				( ( 'let* ( bindings ...  ) body ... )  
					;if reached base, just return desugared body			
					;if last lambda set body to body else another binding create another let
					(if (null? (cdr bindings))
						`((lambda (,(caar bindings)) 
								,@body) 
								,@(cdar bindings))
						`((lambda (,(caar bindings)) 
								,(desugar-let* `(let* ,(cdr bindings) ,@(desugar-let* body) )))
								,@(cdar bindings))
					))
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-let* (car node))) 
						(desugar-let* (cdr node)))
			node)))

;letrec
;	https://www.cs.indiana.edu/~dyb/pubs/fixing-letrec.pdf
;`(letrec ,((vars exprs)...) body ... ) 
; ==> `((lambda vars  
; 		((lambda ( temp1  ... tempn )  
; 			(set! var1 temp1)
;				...
; 			(set! varn tempn)
;  				body)
; 			expr1 ... exprN) )
;				 #f ... #f)
;
;helper to create temp name
(define (get-temp-symbol var)
(string->symbol (string-append "___" (symbol->string var))))

(define (desugar-letrec root)	
	(let ( (node 
			(match root    
				( ( 'letrec ( (vars exprs) ...  ) body ... )  
					`((lambda ,vars  
						,`((lambda ,(map (lambda (var) (get-temp-symbol var)) vars)  
							,@(map (lambda (var) `(set! ,var ,(get-temp-symbol var))  ) vars)
					 			,@body)
						,@exprs) )   
						,@(map (lambda (expr) #f) exprs )
					))
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-letrec (car node))) 
						(desugar-letrec (cdr node)))
			node)))

;letrec*
; ((letrec* ((vars exprs) ...) body ...)
; 	==>	( ( lambda  (var1  ... varn )
; 			(set! var1 expr1)
;			...
; 			(set! varn exprn)
; 			(let () body  ...))
;				 #f .. #f  )
(define (desugar-letrec* root)	
	(let ( (node 
			(match root    
				( ( 'letrec* ( bindings ...  ) body ... )  
					(desugar-let* 
						;desugar let* but bind var to #f
						`(let* ,(map (lambda(binding) `(,(car binding) #f))  bindings)
							;set var to original bindings
							,@(map  (lambda(binding) `(set! ,@binding )) bindings)
					 		,@body)))
				(_  
					root
				))))
			(if (pair? node)
				(append (list (desugar-letrec* (car node))) 
						(desugar-letrec* (cdr node)))
			node)))