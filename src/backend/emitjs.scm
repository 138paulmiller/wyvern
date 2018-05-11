
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
;	memv   		=>  i = list.findIndex((compile-expr expr)); (i==list.length|| list.slice( i) )
;	list   		=>  (list  expr1 expr2 expr3 ... ) = [(compile expr), (compile expr2), (compile expr3) ... ]
;	append 		=>  (append expr1 expr2 expr3 ... ) list.push( (compile expr) (compile expr2) (compile expr3)... );
;	vector 		=> 		
;	vector-set! => 	vec[i]=(compile-expr)
;	vector-ref 	=> 	vec[i]
;	__make_value__  (__make_value__ n args ...) creates a value object of n dimensions 
;	__get_value__   (__get_value__ i value_object) get ith component of value object 
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
	(display body)
	(display"ValueS:")
	(newline)
	(let ((source (string-append (compile-primitives) (compile-values) (compile-body body) )))
		
		(display source (if filename (open-output-file filename) (current-output-port) ))
		))

;compiles the value objects and accessors 
(define (compile-values)
	;for each valuen, create valuen (__make_valuen__ ) and accessors (__get_valuen_0__ ... __get_valuen_n-1__) 
	(fold-right 
		(lambda (valuen str) 
			(symbol->string valuen)	
		)
	"" unique-values 
	)

)

(define (compile-primitives)
;change to accept lists? or desugar all vararg to binary (* 1 2 ... n ) => (__mul__ 1 (__mul__ 2 (... n ) ) )
"const err = function(msg){ console.log(\"ERROR\"+msg);  };
const display = function(a){ return console.log(a);  };
const __empty_list__ = null;
const cons  = function(a, b){var l = [a]; if(b != null) l = l.concat(b); return l;};
const car  = function(a){if(a==__empty_list__) return err(\"Cannot car empty list\"); else return a[0];};
const cdr  = function(a){if(a==__empty_list__) return err(\"Cannot cdr empty list\"); else return a.splice(1);};

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
const and  = function(a, b){if(a&&b) return b; else return false;};
const or  = function(a, b){if(a) return a; else if(b) return b; else return false;};

const __make_value__  = function(n, value_list){return value_list;};
const __get_value__  = function(i, value){if(value!=null)return value[i-1];};
//trampoline for functions 

function __call__(func) {
  while(func && typeof func === 'function') {
    func = func()
  }
  return func;
}


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
			( ()
				"")
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
			"(function(" js-formals ")\n{\n"
				"\tvar __return__ = null;\n"
				(compile-body body)
				;return should set __return__ var
				(compile-expr return) ";\n"
				"\n\treturn __return__;\n"
			"})")))


(define (compile-proc proc args)
	; (display proc )(read-line)
	; 	(display args)(read-line)
	(let (
		(js-args  (if (null? args) "" 
					(compile-expr (car args) ) ))

		(js-proc (compile-expr proc))
		)
		(if (not (null? args))
			(map (lambda(arg) 
				(set! js-args (string-append js-args ", " (compile-expr arg)  )) )
				(cdr args)))
			(string-append 
				"__call__(function(){ \nreturn " js-proc 
					"(" js-args")"
				"})"
			)))


(define (compile-return expr)
	(string-append "\n\t__return__ = " (compile-expr expr)))
				

(define (compile-define sym expr)
	(string-append "\nvar " (symbol->string sym) " =" (compile-expr expr)))

(define (compile-if test then else)	
		(string-append "\nif(" (compile-expr test) "){" 
			(compile-expr then) ";\n}" 
			(if (not (null? else))
				(string-append "\nelse{" 
					(compile-expr else) ";\n}") 
				"\n")))
