;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Desugar 
;	@author Paul Miller 2018
;	Reconstructs Scheme Expressions into primitive expressions 
;---------------------------------------------------------------------------------------------;; 	
;	Derived Expressions 
;---------------------------------------------------------------------------------------------;
; 	cond			
; 	case 						
; 	and 				
; 	or  				
; 	when    			
; 	unless 			
; 	let     			
; 	let*    			
; 	letrec  			
; 	letrec*  			
; 	let-values  		
; 	let*-values 		
; 	begin  				
; 	do  				
; 	delay 			
; 	delay-force 
;	prefixes 				
; 	parameterize  	TODO
; 	case-lambda		TODO
; 	guard  			TODO
; 	quasiquotation 	TODO
;---------------------------------------------------------------------------------------------;
;	Ur-Scheme
;---------------------------------------------------------------------------------------------;
;	lambda	
;	car
; 	cdr
;	quote
; 	set!
;	if
;	force
;	memv
;	list
;	append
;	vector
;	vector-set!
;	vector-ref
;	valuen-i
;	values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(declare (unit desugar))
(use srfi-1)
(require-extension matchable)
(require-extension r7rs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar  
;---------------------------------------------------------------------------------------------;
;	Reconstructs an expression using only primitives
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (desugar root)
	(desugar-delay
	(desugar-delay-force
	(desugar-begin
	(desugar-let*-values 
	(desugar-let-values
	(desugar-letrec*
	(desugar-letrec
	(desugar-let* 
	(desugar-let 
	(desugar-or
	(desugar-and 
	(desugar-cond 
	(desugar-case
	(desugar-unless
	(desugar-when 
	(desugar-do
	(desugar-define
	(desugar-quasiquote
	(desugar-prefix
	(desugar-brackets	
	(desugar-strings 
	root
	))))))))))))))))))))))

;;Unused for now
(define (syntax-error msg root)
 	(call/cc (lambda (e)
 			(display "\n*** Syntax Error:")
 			(display (string-append "At Line: " (number->string line) "***\n" ))
 			(display root)
 			(display "\nMessage:")
 			(display msg)(newline))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; template-desugar  
;---------------------------------------------------------------------------------------------;
;	Recursively reconstruct an expression by using the production
;	given by the caller, and calls the caller for each sub-expression. 
;	To be used by all desugar expression to offload the recursively
;	handling all sub expressions
;---------------------------------------------------------------------------------------------;
;	params:
;		caller 		: the proc that performs the reconstruction 
;		production 	: the reconstructed expression
;	return:
;		new formed expression
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (template-desugar caller production)
	(let ( (node production ))		
		(if (pair? node)
			(append (list  (caller (car node))) 
					( caller (cdr node)))
			node)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-brackets  
;---------------------------------------------------------------------------------------------;
; Transforms all instances of bracket wrapped expressions into 
;	expressions wrapped with parentheses 
;	E.g. [ expr+ ] => ( expr+ )   
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression
;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-brackets root)	
	(template-desugar 
			desugar-brackets
			(match root
				( ( [ expr ... ] )  
					`(,expr))
				(_ root))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-strings
;---------------------------------------------------------------------------------------------;
; Any string objects returned by read will not be wrapped with quotes 
; and will return any escaped chars with the backslash. 
; This procedure will wrap quotes around any string objects read 
; with quotes and escape any characters  
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-strings root)
	(template-desugar 
			desugar-strings
			(if (string? root)
				(string-append "\"" 
					(fold-right 
						(lambda (chr str) 
								(string-append 
									(cond 
										((char=? chr #\newline) "\\n")
										((char=? chr #\") "\\\"")
										((char=? chr #\') "\\\'")
										((char=? chr #\\) "\\\\")
										(else 
											(string  chr)))
									 str)) 
						"" (string->list root) ) 
					"\"")
				root)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-prefix  
;---------------------------------------------------------------------------------------------;
; Transforms all instances of prefixed expressions into 
;	procedure call expressions  
;	E.g. '( expr+ ) => (quote (expr+))   
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression
;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-prefix root)	
	(template-desugar 
			desugar-prefix
			(match root
				( ( ''( expr ... ) )  
					`(quote ,expr))
				( ( '`( expr ... ) )  
					`(quasiquote ,expr))
				( ( ',( expr ... ) )  
					`(unquote ,expr) ) ;"unquote" yields warning
				( ( ',@( expr ... ) )  
					`(unquote-splicing ,expr))
				( #(  expr ...  )  
					`(vector ,expr))
				(_ root))))



(define (expand-qq expr )
   (match expr
	   (  ((or 'qq 'quasiquote) ('unquote datum) )
	     	 `(list ,(expand-qq datum )))
	    
	    ( ((or 'qq 'quasiquote) (('unquote-splicing datum) next ... ) )
	    	;(append (qq datum) (qq `(qq ,next))))
	    	(cons (expand-qq datum) (expand-qq `(qq ,next ))))
	    
	    ( ((or 'qq 'quasiquote) (('quasiquote datum) next ... ) )
	    		
	    		(cons `(list ,`(append ,@(expand-qq `(qq ,datum ))))
						(expand-qq `(qq ,next ) ))
	    		)
	    ( ( (or 'qq 'quasiquote) (datum next ... ) )
	    	(cons (expand-qq `(qq ,datum  ) ) (expand-qq `(qq ,next) )))
	    
	    ( ( (or 'qq 'quasiquote) datum )
	    	(if (null? datum)
	     		datum
	     		`(list (quote ,(expand-qq datum )))))
	    (_ expr)))


(define (desugar-quasiquote root)
	(template-desugar 
			desugar-prefix
			(match root
				(('quasiquote (datums ... ) )
					`(append ,@(expand-qq root)))
			

				; (('quasiquote (datums ... ) )
				; 	`(list ,@(quasiquote-expand root '())))
			
				; (('quasiquote datum )
				; 	`(list ,@(quasiquote-expand `( ,datum ) '())))
				

				; (('quasiquote (datum ) )
				; 	(if(eqv? (car datum) 'unquote-splicing ) 
				; 		 		(desugar-quasiquote `(qq0 ,@(cadr datum))))
				; 	`(list ,(desugar-quasiquote `(qq1 ,datum)))
				; )
				; (('quasiquote (datums ...) )
				; 	`(list ,(map (lambda (datum) 
				; 		(desugar-quasiquote `(qq1 ,datum) ))
				; 		datums))
				; )
				; (('unquote (datums ...) )
				; 	(syntax-error "Unquote not inside quasiquotation" root)
				; )
				; (('quasiquote ( ('unquote datum) ) )
				; 	(desugar-quasiquote datum)
				; )
				; (('quasiquote ( ('unquote datum) datums ...) )
				; 	(list (desugar-quasiquote datum) (desugar-quasiquote (quasiquote datums) ))
				; )
				; (('quasiquote (('unquote-splicing datum) datums ...) )
				; 	(append (desugar-quasiquote datum) (desugar-quasiquote (quasiquote datums) ))
				; )
				;level 1
				; (('qq1 datum  )
				; 	(if (pair? datum ) 
				; 		(cond 
				; 			((eqv? (car datum) 'unquote ) 
				; 		 		(desugar-quasiquote `(qq0 ,(cadr datum))))
				; 			; ((eqv? (car datum) 'unquote-splicing ) 
				; 		 ; 		(desugar-quasiquote `(qq0 ,@(cadr datum))))
				; 			((eqv? (car datum) 'quasiquote ) 
				; 		 		`(quote ,(desugar-quasiquote `(qq0 ,(cadr datum)))))
				; 			(else 
				; 				`(quote ,(desugar-quasiquote `(qq0 ,datum)))))
						
				; 		`(quote ,(desugar-quasiquote `(qq0 ,datum)))))
				; (('qq0 datum  )
				; 	(if (pair? datum )
				; 		(cond
				; 			((eqv? (car datum) 'unquote )
				; 				(syntax-error "Unquote depth does not match quasiquotation" root))
				; 			((eqv? (car datum) 'quasiquote ) 
				; 		 		`(quote ,(desugar-quasiquote `(qq0 ,(cadr datum)))))  
				; 			(else
				; 				(desugar-quasiquote datum)))
				; 			(desugar-quasiquote datum)))

				(_ root))))	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-define
;---------------------------------------------------------------------------------------------;
; Expresses begin according to the following:
;	(define (sym ...) expr ... )
;		(define sym1 (lambda ( sym2 ...) expr...  ))
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression
;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-define root)	
	(template-desugar 
			desugar-define
			(match root
				( ( ('define (syms ...) exprs ... ) )
					(if (or (null? syms) (null? exprs))     
						(syntax-error "Expected: (define (syms+) exprs+ )" root)
						`(define ,(car syms) 
							(lambda ,cdr syms 
								,@exprs ))))
				(_ root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-begin
;---------------------------------------------------------------------------------------------;
; Expresses begin according to the following:
; (begin  expr) 
;	((lambda () expr )) 
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-begin root)
	(template-desugar 
			desugar-begin
			(match root    
				( ('begin body ...  )  
					`((lambda  () ,@body)))
				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-cond
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((cond (else body ...))
; 		(begin body ...)) 
;
; ((cond (test => result))
; 	(let ((temp test))
; 		(if temp 
;			(result temp)))) 
;
; ((cond (test => result) clauses...)
; 	(let ((temp test))
; 		(if temp
; 			(result temp)
; 			(cond clauses ...))))
; ((cond (test))
;	=> test)
;
; ((cond (test) clauses ...)
; 	(let ((temp test))
; 		(if temp
; 			temp
; 			(cond clauses ...))))
;
; ((cond (test body ...))
; 	(if test (begin body ...)))
;
; ((cond (test body ...) clauses ...)
;	(if test
; 		(begin body ...)
; 		(cond clauses ...)))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-cond root)	
	(if (and (pair? root) (eq? 'cond (car root)))
		(template-desugar 
				desugar-cond
				(match root    
					( ('cond ('else body ...))
						`(begin ,@(desugar-cond body)))
		
					(('cond (test '=> result))
						`((lambda (temp)
							,`(if temp 
								(,(desugar-cond result) temp)))  
								,(desugar-cond test) ))
					
					(('cond (test '=> result) clauses ...)
						`((lambda (temp)
							,`(if temp 
								(,(desugar-cond result) temp)
								,(desugar-cond `(cond ,@clauses))))  
								,(desugar-cond test)))

					(('cond (test))
						(desugar-cond test))

					(('cond (test) clauses ...)
						`((lambda (temp)
							,`(if temp
								temp
								,(desugar-cond `(cond ,@clauses)))) 
						,(desugar-cond test)))
					

					(('cond (test body ...))
						`(if ,(desugar-cond test) ,`(begin ,@(desugar-cond body))))


					(('cond ((and test (not 'else) )  body ...) clauses ...)
						 `(if ,(desugar-cond test)
					 		,`(begin ,@(desugar-cond body))
					 		,(desugar-cond `(cond ,@clauses ))))
					(_  
						(syntax-error "Expected: (cond (test expr*)* (else expr*)? )" root)
					)))
		root))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-let
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; (let ((var expr) ... (varN exprN)) body )
; 	((lambda (var... varN ) body  ) expr ... exprN)
; 
; (let tag ((vars exprs) ...) body ...)
; 	((letrec ( 
; 			(tag (lambda (vars )
; 						body )))
; 		tag)
; 			exprs ...)
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-let root)	
	(template-desugar 
			desugar-let
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
								,@exprs)))
				(_  
					root
				))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-let*
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; (let* ((var expr) ... (varN exprN)) body )
;	==> ((lambda (var ) 
;			(let* (... varN ) 
;					body )  ... exprN ) expr)
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-let* root)	
	(template-desugar 
			desugar-let*
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
				(_  root))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get-temp-symbol
;---------------------------------------------------------------------------------------------;
; desugar-letrec helper to create nonrandom names for temporary symbols 
;	for a given symbol
;---------------------------------------------------------------------------------------------;
;	params:
;		var : symbol to create temp name for
;	return:
;		temporary symbol 		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (get-temp-symbol var)
	(string->symbol (string-append "___" (symbol->string var) "___" )))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-letrec
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;	From https://www.cs.indiana.edu/~dyb/pubs/fixing-letrec.pdf
; (letrec ,((vars exprs)...) body ... ) 
; 	((lambda vars  
; 		((lambda ( temp1  ... tempn )  
; 			(set! var1 temp1)
;				...
; 			(set! varn tempn)
;  				body)
; 			expr1 ... exprN) )
;				 #f ... #f)
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-letrec root)	
	(template-desugar 
			desugar-letrec
			(match root    
				( ( 'letrec ( (vars exprs) ...  ) body ... )  
					`((lambda ,vars  
						,`((lambda ,(map (lambda (var) (get-temp-symbol var)) vars)  
							,@(map (lambda (var) `(set! ,var ,(get-temp-symbol var))  ) vars)
					 			,@body)
						,@exprs) )   
						,@(map (lambda (expr) #f) exprs )
					))
				(_  root))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-letrec*
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((letrec* ((vars exprs) ...) body ...)
; 	( ( lambda  (var1  ... varn )
; 		(set! var1 expr1)
;		...
; 		(set! varn exprn)
; 		 body )
;			 #f .. #f  )
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-letrec* root)	
	(template-desugar 
			desugar-letrec*
			(match root    
				( ( 'letrec* ( bindings ...  ) body ... )  
					(desugar-let* 
						;desugar let* but bind var to #f
						`(let* ,(map (lambda(binding) `(,(car binding) #f))  bindings)
							;set var to original bindings
							,@(map  (lambda(binding) `(set! ,@binding )) bindings)
					 		,@body)))
				(_  root))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-and
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((and)
;	 	#t)
; ((and test) 
;		test)
; ((and test tests )
; 		(if test1 
;			(and tests) 
;			#f))))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-and root)
	(template-desugar 
			desugar-and
			(match  root
				(('and) 
				 	#t)

				(('and test)
				 	(desugar-and test))
				
				(('and test testn ... )
					`(if ,(desugar-and test) 
						,(desugar-and `(and ,@testn))
						#f))

				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-or
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
; 
; ((or) 
;		#f)
; ((or test)
;		 test)
; ((or test1 test2 ...)
; 	(let ((x test1))
; 	(if x 
;		x 
;		(or test2 ...))))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-or root)
	(template-desugar 
			desugar-or
			(match  root
				(('or) 
				 	#f)

				(('or test)
				 	(desugar-or test))
				
				(('or test testn ... )
					`((lambda (__or_temp__) 
						,`(if __or_temp__
							__or_temp__
							,(desugar-or `(or ,@testn)))) 
					,(desugar-or test) ))

				(_  root))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-when
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((when test body ...)
; 	(if test
; 		(begin body ...)))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-when root)
	(template-desugar 
			desugar-when
			(match  root
				( ('when test body ...)  
					`(if ,(desugar-when test)
						,`(begin ,@(desugar-when body))))
				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-unless
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
; 
; ((unless test body ...)
; 	(if (not test)
; 		(begin body ...)))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-unless root)
	(template-desugar 
			desugar-unless
			(match  root
				( ('unless test body ...)  
					`(if ,`(not ,(desugar-unless test))
						,`(begin ,@(desugar-unless body))))
				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-case
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((case (key ...) clauses ...)
; 	(let ((atom-key (key ...)))
; 		(case atom-key clauses ...)))
;
; ((case key (else => result))
; 	(result key))
;
; ((case key (else body ...))
; 	(begin body ...))
;
; ((case key ((atoms ...) body ...))
; 	(if (memv key ’(atoms ...))
; 		(begin body ...)))
;
; ((case key
; 	((atoms ...) => result))
; 	(if (memv key ’(atoms ...))
; 		(result key)))
;
; ((case key ((atoms ...) => result)
; 	clause clauses ...)
; 	(if (memv key ’(atoms ...))
; 		(result key)
; 		(case key clause clauses ...)))
;
; ((case key ((atoms ...) body ...) clauses ...)
; 	(if (memv key ’(atoms ...))
; 		(begin body ...)
; 		(case key clauses ...)))
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-case root)
	(template-desugar 
			desugar-case
			(match  root
				( ('case (expr ... ) clauses ...)  
					`((lambda (__atom-key__) 
						,(desugar-case `(case __atom-key__ ,@clauses)))
					,(desugar-case expr)))

				( ('case key ('else '=> result ) ...)  
					`(,@(desugar-case result) ,key ))

				( ('case key ('else body ...))
					`(begin ,@(desugar-case body)))

				( ('case key ((atoms ...) body ...))
					`(if ,`(memv ,key ',atoms )
						,`(begin ,@(desugar-case body))))

				( ('case key ((atoms ...) => result))
					`(if ,`(memv ,key ',atoms )
						,`(,@(desugar-case result) ,key )))

				( ('case key ((atoms ...) => result) clauses ...)
					`(if ,`(memv ,key ',atoms )
						,`(,@(desugar-case result) ,key )
						,`(case ,key ,@clauses)))

				( ('case key ((atoms ...) body ...) clauses ...)
					`(if ,`(memv ,key ',atoms )
						,`(begin ,@body)
						,`(case ,key ,@clauses)))
				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-do
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;
; ((do ((var init step ...) ...) (test expr ...) command ...)
; 	(letrec
; 		((loop
; 			(lambda (var ...)
; 			(if test
; 				(begin
; 					(if #f #f)
; 					expr ...)
; 				(begin
; 					command
; 					...
; 					(loop (do "step" var step ...)
; 					...))))))
; 		(loop init ...)))
; ((do "step" x)
; 	x)
; ((do "step" x y)
; 	y)
;
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-do root)	
	(template-desugar 
			desugar-do
			(match root    
				(('do ((vars inits steps ) ...) (test exprs ...) commands ...)
					`(letrec
						((loop
							(lambda (,@vars)
							(if ,test
								(begin
									(if #f #f)
									,@exprs )
								(begin
									,@commands
									,`(loop ,@(desugar-do `(do step ,vars ,steps )))
									)))))
						(loop ,@inits )))
				(('do 'step x)
					x)
				(('do 'step x y)
					y)

				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; make-get-record-name  
;---------------------------------------------------------------------------------------------;
; Let value helper used to construct a procedure to get the name of next record object created
;---------------------------------------------------------------------------------------------;
;	params:
;	return:
;		record name "getter"		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (make-get-record-name )
	(let ((r 0 ))
		(lambda ( )
			(set! r (+ r 1))
			(string-append  " record-" (number->string r)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;make-get-record-component 
;---------------------------------------------------------------------------------------------;
; Let value helper used to construct a procedure to get the name of procedure to access each
;	compenent of the record object.
; Given a record object of dimension n, it's components can be accessed valuen-i
; The procedure return is used to get the next i in the function valuen-i
; valuen-i should compile to valuen-1, valuen-2,  ...  valuen-n .. 
; 
;---------------------------------------------------------------------------------------------;
;	params:
;	return:
;		record component "getter"		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (make-get-record-component val)
		(let ((i 0 )(n (length val)))
			(lambda ()
				(set! i (+ i 1))
				(string->symbol (string-append "value" 
								(number->string n) "-"				
								(number->string i))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-let-values
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;let values uses the record approach to return a record object and access individual values
; ((let-values ((vars expr) ...) body ...)
; (let ( ((record1 expr) ... (recordn exprn) ) ) 
; 	(let ( (var1 (valuen_1 record))
; 			...
; 			(varn (valuen_n record)))
; 	 body))
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-let-values root)
	(template-desugar 
			desugar-let-values
			(match  root
				(('let-values ((vals exprs) ...) body ...)
					;create the value proc "getter"
					(let* ( 
							;get all record names, wrap proc in lambda that takes an arg
							(record-names (map 
								((lambda ()
								(let ((get-record-name (make-get-record-name)))
									(lambda (val) (get-record-name) ))))
								vals))
							;create a name getter for the binding to use
							(get-record-name (make-get-record-name))
							(bindings   
								;for each value
								(fold-right 
									(lambda (val right)
									 (let ((left 
										(let ((record-name (get-record-name) )
												;for each value create the accessor 
												(get-record-component (make-get-record-component val)))
										 	; for each component of val, slice list into parent list
											(map  
												(lambda (comp) `(,comp (,(get-record-component) ,record-name)  ))
												val))))
									 	`(,@left ,@right)))
								     '()  vals)))
						`((lambda ,record-names
							,(desugar-let `(let ,bindings
								,@(desugar-let-values body))))
						,@(desugar-let-values exprs) )))
				(_  root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-let*-values
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
;let values* uses the record approach to return a record object and access individual values
; ((let-values ((vars expr) ...) body ...)
; (let ( ((record1 expr) ... (recordn exprn) ) ) 
; 	(let* ( (var1 (valuen_1 record))
; 			...
; 			(varn (valuen_n record)))
; 	 body))
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-let*-values root)
		(template-desugar 
			desugar-let*-values 
			(match  root
				(('let*-values ((vals exprs) ...) body ...)
					;create the value proc "getter"
					(let* ( 
							;get all record names, wrap proc in lambda that takes an arg
							(record-names (map 
								((lambda ()
								(let ((get-record-name (make-get-record-name)))
									(lambda (val) (get-record-name) ))))
								vals))
							;create a name getter for the binding to use
							(get-record-name (make-get-record-name))
							(bindings   
								;for each value
								(fold-right 
									(lambda (val right)
									 (let ((left 
										(let ((record-name (get-record-name) )
												;for each value create the accessor 
												(get-record-component (make-get-record-component val)))
										 	; for each component of val, slice list into parent list
											(map  
												(lambda (comp) `(,comp (,(get-record-component) ,record-name)  ))
												val))))
									 	`(,@left ,@right)))
								     '()  vals)))
						`((lambda ,record-names
							,(desugar-let* `(let* ,bindings
								,@(desugar-let*-values body) )))
						,@(desugar-let*-values exprs) )))
				(_  root))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-force
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
; delay-force
; ((delay-force expression)
; 	(make-promise #f (lambda () expression)))
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-delay-force root)
	(template-desugar 
		desugar-delay-force
		(match root
			( ('delay-force  expr )
				(list (cons  #f  (lambda () expr) )))
			(_ root))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; desugar-delay
;---------------------------------------------------------------------------------------------;
; Expresses according to the following:
; delay
; ((delay expression)
; 	(delay-force (make-promise #t expression)))))
;---------------------------------------------------------------------------------------------;
;	params:
;		root : root expression
;	return:
;		new formed expression		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (desugar-delay root)
	(template-desugar 
		desugar-delay
		(match root
			( ('delay  expr )
				(list (cons  #t  (lambda () expr) )))
			(_ root))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;WIP;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;delay and delay force helpers
;make-promise 
; (define (make-promise done? proc)
; 		(list (cons done? proc)))
;force - trampolines back and forth until a value created by delay, not delay-force
; (define (force promise)
; 	(if (promise-done? promise)
; 		(promise-value promise)
; 		(let ((promise* ((promise-value promise))))
; 			(unless (promise-done? promise)
; 				(promise-update! promise* promise))
; 			(force promise))))
; ;promise accesors
; (define (promise-done? p)
;  	(car (car p)))

; (define ( promise-value p)
; 	 (cdr (car p)))

; (define (promise-update! new old)
; 		(set-car! (car old) (promise-done? new))
; 		(set-cdr! (car old) (promise-value new))
; 		(set-car! new (car old)))

; force
; ((delay-force expression)
; 	(make-promise #f (lambda () expression)))
; Primitive!!!!
; (define (desugar-force root)
; 	(display root)(read-line)
; 	(template-desugar 
; 		desugar-force
; 		(match root
; 			( ('force  expr )
; 				`(if (car (car ,expr))
; 					(cdr (car ,expr))
; 					(let ((expr* ( (cdr (car ,expr)))))
; 						(unless (car (car ,expr))
; 							(set-car! (car ,expr) (car (car expr*)))
; 							(set-cdr! (car ,expr) (cdr (car expr*)))
; 							(set-car! expr* (car ,expr)))
; 						,(desugar-force `(force ,expr)))))
; 			(_ root))))



;paraterize helper
; (define (make-parameter init . o)
; 	(let* ((converter
; 		(if (pair? o) (car o) (lambda (x) x)))
; 			(value (converter init)))
; 			(lambda args
; 				(cond
; 					((null? args)
; 						value)
; 					((eq? (car args) <param-set!>)
; 						(set! value (cadr args)))
; 					((eq? (car args) <param-convert>)
; 						converter)
; 					(else
; 						(error "bad parameter syntax"))))))


; parameterize
; ((parameterize ("step") ((param value p old new) ...) () body)
; 	(let ((p param) ...)
; 		(let 
; 			((old (p)) ...
; 			(new ((p <param-convert>) value)) ...)
; 			(dynamic-wind
; 			(lambda () (p <param-set!> new) ...)
; 				(lambda () . body)
; 					(lambda () (p <param-set!> old) ...)))))

; ((parameterize ("step") args ((param value) . rest) body)
; 	(parameterize ("step") ((param value p old new) . args) rest body))

; ((parameterize ((param value) ...) . body)
; 	(parameterize ("step") () ((param value) ...) body))


