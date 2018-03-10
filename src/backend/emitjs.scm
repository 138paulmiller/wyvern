
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Ur-Scheme to JS  
;---------------------------------------------------------------------------------------------;
; define 		=> var sym = (compile expr)
; 	lambda		=> anonymous function with return == last expr and wrapped with (function(formals){exprs...})
;   return 		=> lambda return value
;	if      	=> use if(test){(compile-expr then)}else{ (compile-expr else ) }
;	display 	=> 		console.log((compile-expr expr));
;	car			=> list[0]
; 	cdr			=> list.slice(1)
; 	set!    	=> (set! var expr2 ) var = (compile-expr expr1)
;	quote 		=? just write symbol 
;	force  		??
;	memv   		=>  i = list.findIndex((compile-expr expr)); (i==list.lenght|| list.slice( i)
;	list   		=>  (list  expr1 expr2 expr3 ... ) = [(compile expr), (compile expr2), (compile expr3) ... ]
;	append 		=>  (append expr1 expr2 expr3 ... ) list.push( (compile expr) (compile expr2) (compile expr3)... );
;	vector 		=> 		
;	vector-set! => 	vec[i]=(compile-expr)
;	vector-ref 	=> 	vec[i]
;	valuen-i  	=> 	valuen-i = get_value_n(value_n_obj, i){return value_n_obj[i];}
;	values 		=> 	(values (compile-expr  expr0) (compile-expr  expr1) ... (compile-expr  exprn)) = {0 : 0, 1:1, n:n};   
;	__make_valuen__ => return valuen( (compile exprs ...)) ;structure must be defined before hand!
;	__get_valuen_i__ => return __value_t__.value_i //where value_t is the structure with attribute value_i
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
; Test on http://www.webtoolkitonline.com/javascript-tester.html
; Does not rely on syntax manipulation since most features will fall through to JS (more transpile than compile)

(declare (uses analyze))
(declare (uses util))
(declare (uses desugar))
(declare (unit emitjs))
(require-extension matchable)
(use srfi-1) ;assoc
; ;returns pair or #f
; (define (get-def alist key )
; 	(assoc key alist eqv? ) )

; ;returns pair or #f
; (define (add-def alist key datum )
; 	(alist-cons key datum alist ) )


(define (emitjs body filename)
	(display"ValueS:")
	(display unique-values)
	(newline)
	(let ((source (string-append (compile-primitives) (compile-body body) )))
		(display source (open-output-file filename) )
		))


(define (compile-primitives)
;change to accept lists? or desugar all vararg to binary (* 1 2 ... n ) => (__mul__ 1 (__mul__ 2 (... n ) ) )
"

const __add__ = function(a, b){return a+b;};
const __sub__ = function(a, b){return a-b;};
const __mul__ = function(a, b){return a*b;};
const __div__ = function(a, b){return a/b;};
const __lt__  = function(a, b){return a<b;};
const __lte__  = function(a, b){return a<=b;};
const __gt__  = function(a, b){return a>b;};
const __gte__  = function(a, b){return a>=b;};
const __ate__  = function(a, b){return a==b;};
const __ste__  = function(a, b){return a===b;};
const __eq__  = function(a, b){return _.isEqual(a,b);};
const __eqv__  = function(a, b){return _.isEqual(a,b);};
const display  = function(a){return console.log(a);};
const and  = function(a, b){if(a&&b) return b; else return false;};
const or  = function(a, b){if(a) return a; else if(b) return b; else return false;};
"
)

(define (compile-body exprs)
	(let ((js ""))
		(map (lambda(expr)
				(set! js (string-append js (compile-expr expr) ";\n\n" ) ))
			exprs)
		js))

;match the ur-scheme to produce
(define (compile-expr expr)
	(if (null? expr)
		" "
		(match expr
			( ('lambda ( formals ... ) body ... return)
				(compile-lambda formals body return))
			;check special forms
			( ( 'if test then  )
				(compile-if test then '()))
			( ( 'if test then else)
				(compile-if test then else))
			( ('return expr) 
				(compile-return expr))
			( ('define sym expr) 
				(compile-define sym expr))
			;check if application after special forms
			( ( args ... )
				(compile-proc (car args) (cdr args)))

			( _ 
				(cond
					((char? expr) (string expr))
					((number? expr) (number->string expr))
					((symbol? expr) (symbol->string expr))
					((string? expr) expr)
					(else 
						(if (pair? expr)
							(string-append 
								(compile-expr (car expr))
								(compile-expr (cdr expr)))
							(and (display "\nError:Unhandled emit:")(display expr))

						)))))))

(define (compile-lambda formals body return)
	(let (
		(js-formals  (if (null? formals) "" 
					(symbol->string  (car formals) ) )))
		(if (not (null? formals))
			;set remaining args sperated by commas
			(map (lambda(formal) 
					(set! js-formals (string-append js-formals ", " (symbol->string formal) ) )) 
				(cdr formals)))
		(string-append 
			"\n(function(" js-formals ")\n{\n"
				"\tvar __return__ = null;\n"
				(compile-body body)
				;return should set __return__ var
				(compile-expr return) ";\n"
				"\n\treturn __return__;\n"
			"})")))


(define (compile-proc proc args)
	(let (
		(js-args  (if (null? args) "" 
					(compile-expr (car args) ) ))

		(js-proc (compile-expr proc))
		)
		(if (not (null? args))
			(map (lambda(arg) 
				(set! js-args (string-append js-args ", " (compile-expr arg)  )) )
				(cdr args)))
			(string-append " " 
				js-proc "("
				js-args")"
			)))


(define (compile-return expr)
	(string-append "\n\t__return__ =" (compile-expr expr) ))
				

(define (compile-define sym expr)
	(string-append "\nvar " (symbol->string sym) " =" (compile-expr expr)))

(define (compile-if test then else)	
		(string-append "\nif(" (compile-expr test) "){" 
			(compile-expr then) ";\n}" 
			(if (not (null? else))
				(string-append "\nelse{" 
					(compile-expr else) ";\n}") 
				"\n")))
