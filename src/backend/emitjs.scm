
(declare (uses analyze))
(declare (uses util))
(declare (uses desugar))
(declare (unit emitjs))
(require-extension matchable)
(use srfi-1) ;assoc
;Does not rely on syntax manipulation since most features will fall through to JS (more transpile than compile)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ur-Scheme to JS  
;---------------------------------------------------------------------------------------------;
; 	lambda		=> anonymous function with return == last expr and wrapped with (function(formals){exprs...})
;	car			=> list[0]
; 	cdr			=> list.slice(1)
;	quote 		=? just write symbol 
; 	set!    	=> (set! var expr2 ) var = (emitjs expr1)
;	if      	=> use if(test){(emitjs then)}else{ (emitjs else ) }
;	force  		??
;	memv   		=>  i = list.findIndex((emitjs expr)); (i==list.lenght|| list.slice( i)
;	list   		=>  (list  expr1 expr2 expr3 ... ) = [(compile expr), (compile expr2), (compile expr3) ... ]
;	append 		=>  (append expr1 expr2 expr3 ... ) list.push( (compile expr) (compile expr2) (compile expr3)... );
;	vector 		=> 		
;	vector-set! => 	vec[i]=(emitjs)
;	vector-ref 	=> 	vec[i]
;	valuen-i  	=> 	valuen-i = get_value_n(value_n_obj, i){return value_n_obj[i];}
;	values 		=> 	(values (emitjs  expr0) (emitjs  expr1) ... (emitjs  exprn)) = {0 : 0, 1:1, n:n};   
;	display 	=> 		console.log((emitjs expr));
;
;
;
;---------------------------------------------------------------------------------------------;
; Tail-calls will be handled by having all user defined lambdas return thunks containing lambda body.
;	If the function is not tail call-recursive this will still work, it will just return a thunk that returns the value
;   
;	function repeat(num) {
;   	return function() {
;     		if (num <= 0) 
;				return
;     		else
;				//do stuff
;   	  		return repeat(operation, --num)
;  	 	}
; 	}	

; 	function trampoline(fn) {
; 	  while(fn && typeof fn === 'function') {
;  	   fn = fn()
;  	 }
; 	}
;
; And each function call becomes trampoline((compile lambda))
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;returns pair or #f
(define (get-def alist key )
	(assoc key alist eqv? ) )

;returns pair or #f
(define (add-def alist key datum )
	(alist-cons key datum alist ) )


(define (emitjs root)
	(if (pair? root)
		(begin 
			(emitjs (car root))
			(emitjs (cdr root)))
		(emit-ur root)
	))

;match the ur-scheme to produce
(define (emit-ur expr)
	; (match expr
	; 	(
	; 		)
	; )
	#f
)


(define (emit-lambda formals body return)
	#f
)



; 	lambda		=> anonymous function with return == last expr and wrapped with (function(formals){exprs...})
;	car			=> list[0]
; 	cdr			=> list.slice(1)
;	quote 		=? just write symbol 
; 	set!    	=> (set! var expr2 ) var = (emitjs expr1)
;	if      	=> use if(test){(emitjs then)}else{ (emitjs else ) }
;	force  		??
;	memv   		=>  i = list.findIndex((emitjs expr)); (i==list.lenght|| list.slice( i)
;	list   		=>  (list  expr1 expr2 expr3 ... ) = [(compile expr), (compile expr2), (compile expr3) ... ]
;	append 		=>  (append expr1 expr2 expr3 ... ) list.push( (compile expr) (compile expr2) (compile expr3)... );
;	vector 		=> 		
;	vector-set! => 	vec[i]=(emitjs)
;	vector-ref 	=> 	vec[i]
;	valuen-i  	=> 	valuen-i = get_value_n(value_n_obj, i){return value_n_obj[i];}
;	values 		=> 	(values (emitjs  expr0) (emitjs  expr1) ... (emitjs  exprn)) = {0 : 0, 1:1, n:n};   
;	display 	=> 		console.log((emitjs expr));
