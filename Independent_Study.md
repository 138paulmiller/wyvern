# Scheme Transpiler 
#### Independent Project
Student Paul Miller

Adviser Prof Kevin Wortman Ph.D

### Motivation

Scheme has little influence on major software projects out today. So, how could Scheme adapt in order to maintain a language of choice for developers? One answer would be to improve the standard library or to increase usability amongst modern tools, such as a Scheme frontend into the Qt Framework. While others may argue that an improvement of the syntax may bring in more users. 

For this project, we decided to help push Scheme into the world of Web Applications by creating a Scheme to JavaScript transpiler. This will allow users to develop client or server side Scheme applications  that will make use of many of the features built into Javascript. 

### Approach

Initially, this project was going to be written in Python and include modules for Tokenizing and Parsing Scheme syntax into an Abstract-Syntax-Tree (AST).  The transpiler would then pass the AST through multiple micropasses that would reconstruct the syntax into a core representation of the language. However a change in the design occurred after consulting with Professors Kevin Wortman and Kenytt Avery, that led the transpiler to be written in Scheme. I decided on the Chicken Scheme implementation because of their module system that simplifies extension installation. By making this change, the AST parsing was greatly simplified by employing Scheme’s built-in read procedure. 
This procedure read from the import port and returned a list representation of the program. 

This became the seed AST. After reviewing the syntax of R7RS Scheme, designing the core Scheme representation became more clear. The core representation is variation of Scheme that provides only minimal features, all of which can be used to derive other features. 
The let expression is the simplest example of an derived expression consisting of only lambda expressions. Because Scheme is almost a purely functional language, it is encouraged to program in a purely functional manner. 

Since variable assignments, such as let, are outside this paradigm, it would make sense that these do not belong in the core representation. For Scheme, it can be shown that all let expressions are merely lambda expressions. 

Below is an example of achieving let behavior using only lambdas. 

    (let     
       ((a 3) 
        (b 5)) 
          (+ a b) )
 =>
      
      ((lambda (a b) 
          (+ a b) )  
        3 5)

The same is true about all variations of let, such as let*, letrec as well as most features of the language. 

Below is example of deriving let* using lambda expressions.

    (let* 
        ((a 3) 
        (b (+ a a))) 
           (* a b) )
=>

      ((lambda (a) 
         ((lambda (b)
             (* a b)) 
          (+ a a)))  
       3)

After discussion with Professor Wortman, I concluded that pattern matching would greatly simplify AST reconstruction process. So a pattern matching Chicken Scheme Extension  matchable was used to achieve the syntax transformations,  otherwise known as desugaring.
Implementation

The transpiler is broken up into four major modules, entry_point, desugar,  frontend, and  backend.

The entry_point defines the repl as well handling command-line arguments. After reading the input from the input port, the entry_point sends the AST to the desugar module. 

The desugar module reconstructs the input AST into an AST representation using only core features of the language. Each pass makes use of the matchable extension to capture the relevant data from the AST. The reconstruction is achieved by defining procedures that will reconstruct a single derived expression into its core representation.

The result of each pass is then passed down to the next procedure. Some passes do not reconstruct the expression completely but rather pass the burden onto a later stage. For example, desugaring letrec* delegates a remainder of the reconstruction back to the let* desugar pass. Below is the procedure definition.


    (define (desugar-letrec* root)   
     (template-desugar desugar-letrec*
        (match root    
          ( ( 'letrec* ( bindings ...  ) body ... )
                  ;NOTE the call to a previously defined pass  
                  (desugar-let*          
                  ;desugar let* but bind var to #f
                  `(let* ,(map (lambda(binding) `(,(car binding) #f))  bindings)
                      ;set var to original bindings
                      ,@(map  (lambda(binding) `(set! ,@binding )) bindings)
                               ,@body)))
        (_ root))))


In the desugar stage, some expressions are reconstructed to make use of procedures that do not exist in Scheme, but are a component of the core scheme and are defined as primitive procedures in the backend runtime. For example, let-values is translated into an AST that calls a procedure __make-valueN__ which returns a  __valueN__ object. The value object’s elements are accessed with __get__valueN_i__ where N is number of values and i is the ith value. Each value object returns is passed into a parameter named __value_tX__ where x is a unique number used to identify the value object. 

For a better explanation of this reconstruction solution, an example of this transformation can be seen below. It is not the most elegant solution, but it works for now Notice that each value is really just a list. 

    (let-values (((a b) (values 1 2)))
        (display a) (display b) )
=>
  
    (((lambda ( __value_t1__)  
        ((lambda (a b)
              (display a) (display b))
          (__get_value__ 1  __value_t1__)
          (__get_value__ 2  __value_t1__)))
       ;NOTE the first argument of _make_value is the number of components, not a value
      (__make_value__ 2 (cons 1 (cons 2 __empty_list__)))))

The current version of this transpiler does not currently support make-promise, parameterize, and call/cc. There are plans to add this functionality in the future. 

After the AST is reconstructed, it is passed into the target specific backend. This portion of the code handles the code generation stage. There exist various helper procedures in the analyze module. As of now, there are only two procedures, only one of which is being used. The unused procedure is used to return the list of the free variables of a given lambda expression. The other is used to produce a set of all unique __value__t_ objects that are instantiated. 

Currently, the only backend implemented is Javascript. The desugaring stages also rename most of the Scheme primitives, expecting that these primitives will be defined in the target runtime. There are a series of primitives functions defined in Javascript that must be defined in order for much of the core Scheme functionality to work. One such example can be seen below. 

    (list 1 (+2 3) 4 “Hello”)
desugared => 

    (cons 1 ( cons (__add__ 2 3) (cons 4 (cons “Hello” __empty_list__) )))

JS Runtime

    const __empty_list__ = null; 
    const cons = function(a, b){var l = [a]; if(b != null) l = l.concat(b); return l;};
    const __add__ = function(a, b){return a+b;};

The emitjs module is responsible for compiling the core AST into syntactically correct Javascript. In the current working version the generated code is very messy and makes use of Javascript’s anonymous functions. In future revisions, I plan to move away from relying on anonymous functions in order to generated more general backend stages that can produce multiple targets, which is necessary since many lower-level languages do not support closures.

One more feature of the transpiled Scheme code, is the the generated Javascript code maintains Scheme compliant tail-call optimization. This is achieved by defining a runtime  primitive ____call____ in Javascript, such that every procedure call is delayed (or lazified) and passed as an argument into __call__. Also, each return value is also delayed to return a function whose body is the original return value. An example of this can be seen below (Note, terribly unreadable generated code).

Given the JS function:


    function __call__(func) {
        while(func && typeof func === 'function') {
          func = func()
        }
        return func;
     }

and the Scheme source:


    (define loop (a)  
      (if (> a 0)  
      (loop(- a 1) ) ) )
      
      
Transpiler generates =>

      __call__(
      function(){
      return define(loop, __call__(
      function(){
      return a()}), __call__(function(){
      return __eval_if__((function()
      {
          var __return__ = null;
          __return__ = __call__(function(){
      return __gt__(a, 0)});
          return __return__;
      }), (function()
      {
          var __return__ = null;
          __return__ = __call__(function(){
      return loop(__call__(function(){
      return __sub__(a, 1)}))});
          return __return__;
      }), (function()
      {
          var __return__ = null;
          __return__ = false;
      return __return__;}))}))});

the same generated code cleaned up by hand =>


      T_F0 = function(){
          return define(loop, __call__(T_F1), __call__(T_F2))
      };
      T_F1 = function(){
          return a()
      };
      T_F2 = function(){
          return __eval_if__(T_F3, T_F5, T_F8)
      };
      T_F3 = function(){
          var __return__ = null;
          __return__ = __call__(T_F4);
          return __return__;
      };
      T_F4 = function(){
          return __gt__(a, 0)
      };
      T_F5 = function(){
          var __return__ = null;
          __return__ = __call__(T_F6);
          return __return__;
      };
      T_F6 = function(){
          return loop(__call__(T_F7))
      };
      T_F7 = function(){
          return __sub__(a, 1)
      };
      T_F8 = function(){
          var __return__ = null;
          __return__ = false;
          return __return__;
      };

      __call__(T_F0);

Because the generated code is unreadable, making it difficult to debug, the next stage in development would be to generate code similar to the cleaned up version. This will hopefully simplify targeting backends like C and LLVM where anonymous functions can not be exploited)

### Looking Back 
Understanding the pros and cons of using one language over another would have prevented the major project redesign that occured during development.  Before this project, I knew nothing about pattern-matching as an syntax analysis method. Besides the usage of regular expressions discussed in the Compilers and Theory of Computation courses, I was only aware of using patterns to define tokens, not necessarily syntactic reconstruction.  
    
### See Also

- Scheme Transpiler 
  - https://github.com/138paulmiller/wyvern
- R7RS Document
  - http://www.larcenists.org/Documentation/Documentation0.98/r7rs.pdf
- Chicken Scheme Extension Matchable 
  - http://wiki.call-cc.org/eggref/4/matchable

