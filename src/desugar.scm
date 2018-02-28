(declare (unit desugar))
(use srfi-1)
(require-extension matchable)
(require-extension r7rs)
(define (syntax-error msg)
 	(call/cc (lambda (e)
 			(display msg)
 		)))

(define (desugar root)
	 (desugar-begin
	 (desugar-let-values* 
	 (desugar-let-values
	; (desugar-letrec*
	; (desugar-letrec
	; (desugar-let* 
	; (desugar-let 
	; (desugar-or
	; (desugar-and 
	; (desugar-cond 
	; (desugar-case
	; (desugar-unless
	; (desugar-when 
	(desugar-do
	(desugar-brackets	
	(desugar-quote-strings 
		root
	)))))))
;;)))))))))))

;

; condition			x
; quasiquotation 	?
; case 				x			
; and 				x
; or  				x
; when    			x
; unless 			x
; let     			x
; let*    			x
; letrec  			x
; letrec*  			x
; let-values  		?
; let*-values 		?
; begin  			x	
; do  				
; delay 
; delay-force 		
; parameterize  	
; case-lambda		
; guard  			?
; define			?

;brackets
; [expr...] ==> (expr ... )
(define (desugar-brackets root)	
	(let ( (node 
			(match root    
				( ( [ expr ... ] )  
					`(,expr))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-brackets (car node))) (desugar-brackets (cdr node)))
				node)))

; strings - any string objects read by (read) will be wrapped with quotes
;wrap any strings with quotes
(define (desugar-quote-strings root)
	(let ( (node 
			(if (string? root)
				(string-append "\"" 
					(fold-right 
						(lambda (chr str) 
								(string-append 
									(cond 
										((char=? chr #\newline) "\n")
										((char=? chr #\") "\\\"")
										((char=? chr #\') "\\\'")
										(else 
											(string  chr)))
									 str)) 
						"" (string->list root) ) 
					"\"")
				root)))
			(if (pair? node)
				(append (list (desugar-quote-strings (car node))) (desugar-quote-strings (cdr node)))
				node)))



;begin
; (begin  expr) 
;	((lambda () expr ))
(define (desugar-begin root)	
	(let ( (node 
			(match root    
				( ('begin body ...  )  
					`((lambda  () ,@body)))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-begin  (car node))) (desugar-begin (cdr node)))
				node)))

;condition 
; ((cond (else body ...))
; 		(begin body ...)) 

; ((cond (test => result))
; 	(let ((temp test))
; 		(if temp 
;			(result temp)))) 

; ((cond (test => result) clauses...)
; 	(let ((temp test))
; 		(if temp
; 			(result temp)
; 			(cond clauses ...))))
; ((cond (test))
;	=> test)

; ((cond (test) clauses ...)
; 	(let ((temp test))
; 		(if temp
; 			temp
; 			(cond clauses ...))))

; ((cond (test body ...))
; 	(if test (begin body ...)))

; ((cond (test body ...) clauses ...)
;	(if test
; 		(begin body ...)
; 		(cond clauses ...)))

(define (desugar-cond root)	
	(let ( (node 
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


				(('cond (test body ...) clauses ...)
					 `(if ,(desugar-cond test)
				 		,`(begin ,@(desugar-cond body))
				 		,(desugar-cond `(cond ,@clauses ))))
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
				(_  root))))
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
	(display var)
	(read-line)
	(string->symbol (string-append "___" (symbol->string var) "___" )))

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
				(_  root))))
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
; 			 body )
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
				(_  root))))
			(if (pair? node)
				(append (list (desugar-letrec* (car node))) 
						(desugar-letrec* (cdr node)))
			node)))


; and
; ((and)
;	 	#t)
; ((and test) 
;		test)
; ((and test tests )
; 		(if test1 
;			(and tests) 
;			#f))))
(define (desugar-and root)
	(let ( (node 
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
			(if (pair? node)
				(append (list (desugar-and (car node))) (desugar-and (cdr node)))
				node)))


; or
; ((or) 
;		#f)
; ((or test)
;		 test)
; ((or test1 test2 ...)
; 	(let ((x test1))
; 	(if x 
;		x 
;		(or test2 ...))))

(define (desugar-or root)
	(let ( (node 
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
			(if (pair? node)
				(append (list (desugar-or (car node))) (desugar-or (cdr node)))
				node)))


; when
; ((when test body ...)
; 	(if test
; 		(begin body ...)))
(define (desugar-when root)
	(let ( (node 
			(match  root
				( ('when test body ...)  
					`(if ,(desugar-when test)
						,`(begin ,@(desugar-when body))))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-when (car node))) (desugar-when (cdr node)))
				node)))



; unless
; ((unless test body ...)
; 	(if (not test)
; 		(begin body ...)))
(define (desugar-unless root)
	(let ( (node 
			(match  root
				( ('unless test body ...)  
					`(if ,`(not ,(desugar-unless test))
						,`(begin ,@(desugar-unless body))))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-unless (car node))) (desugar-unless (cdr node)))
				node)))

;case 
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
(define (desugar-case root)
	(let ( (node 
			(match  root
				( ('case (expr ... ) clauses ...)  
					`((lambda (__atom-key__) 
						,(desugar-case '(case __atom-key__ ,clauses)))
					,(desugar-case expr)))

				( ('case key ('else '=> result ) ...)  
					`(,@(desugar-case result) ,key ))

				( ('case key ('else body ...))
					`(begin ,@(desugar-case body)))

				( ('case key ((atoms ...) body ...))
					`(if ,`(memv ,key ',atoms )
						,`(begin ,@(desugar-case body))))

				( (case key ((atoms ...) => result))
					`(if ,`(memv ,key ',atoms )
						,`(,@(desugar-case result) ,key )))

				( (case key ((atoms ...) => result) clauses ...)
					`(if ,`(memv ,key ',atoms )
						,`(,@(desugar-case result) ,key )
						,`(case ,key ,@clauses)))

				( (case key ((atoms ...) body ...) clauses ...)
					`(if ,`(memv ,key ',atoms )
						,`(begin ,@body)
						,`(case ,key ,@clauses)))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-case (car node))) (desugar-case (cdr node)))
				node)))


;do TODO !!!!!
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
(define (desugar-do root)	
	(let ( (node 
			(match root    

				(('do ((vars inits steps ...) ...) (test exprs ...) commands ...)
					(display vars)(read-line)(display inits)(read-line)(display steps)(read-line)
					`(letrec
						((loop
							(lambda (,@vars)
							(if ,test
								(begin
									(if #f #f)
									,@exprs )
								(begin
									,@commands
									,`(loop ,@(desugar-do `(do step ,vars ,@steps) ))
									)))))
						(loop ,@inits )))
				(('do 'step x)
					x)
				(('do 'step x y)
					y)

				(_  root))))
			(if (pair? node)
				(append (list (desugar-do  (car node))) (desugar-do (cdr node)))
				node)))




;Let value helpers
; make-get-record-name  
; returns a lambda that takes in the var for each var and will 
; return the next record named associated with that var 
(define (make-get-record-name )
	(let ((r 0 ))
		(lambda ( )
			(set! r (+ r 1))
			(string-append  " record-" (number->string r)))
	)
)
;make-get-record-component 
;for the component of the values (val) given it will this proc 
; returns a lambda used count the next i in the function valuen-i
; valuen_i should compile to valuen->_1, valuen->_2,  ...  valuen->_n .. 
(define (make-get-record-component val)
		(let ((i 0 )(n (length val)))
			(lambda ()
				(set! i (+ i 1))
				(string->symbol (string-append "value" 
								(number->string n) "-"				
								(number->string i))))))

;let values
; uses the record approach to return a record object and access individual values
; ((let-values ((vars expr) ...) body ...)
; (let ( ((record1 expr) ... (recordn exprn) ) ) 
; 	(let ( (var1 (valuen_1 record))
; 			...
; 			(varn (valuen_n record)))
; 	 body))

(define (desugar-let-values root)
	(let ( (node 
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
								,@(desugar-let-values* body))))
						,@(desugar-let-values* exprs) )))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-let-values (car node))) (desugar-let-values (cdr node)))
				node)))


;let values*
; uses the record approach to return a record object and access individual values
; ((let-values ((vars expr) ...) body ...)
; (let ( ((record1 expr) ... (recordn exprn) ) ) 
; 	(let* ( (var1 (valuen_1 record))
; 			...
; 			(varn (valuen_n record)))
; 	 body))
(define (desugar-let-values* root)
	(let ( (node 
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
							,(desugar-let* `(let* ,bindings
								,@(desugar-let-values* body) )))
						,@(desugar-let-values* exprs) )))
				(_  root))))
			(if (pair? node)
				(append (list (desugar-let-values* (car node))) (desugar-let-values* (cdr node)))
				node)))

; (define (values . things)
;   (call-with-current-continuation
;     (lambda (cont) (apply cont things))))


; (define call/cc call/cc)
; (define values #f)
; (define call-with-values #f)
; (let ((magic (cons 'multiple 'values)))
;   (define magic?
;     (lambda (x)
;       (and (pair? x) (eq? (car x) magic)))) 

;   (set! call/cc
;     (let ((primitive-call/cc call/cc))
;       (lambda (p)
;         (primitive-call/cc
;           (lambda (k)
;             (p (lambda args
;                  (k (apply values args))))))))) 

;   (set! values
;     (lambda args
;       (if (and (not (null? args)) (null? (cdr args)))
;           (car args)
;           (cons magic args)))) 

;   (set! call-with-values
;     (lambda (producer consumer)
;       (let ((x (producer)))
;         (if (magic? x)
;             (apply consumer (cdr x))
;             (consumer x))))))
