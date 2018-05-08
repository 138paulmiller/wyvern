# wyvern
Scheme Transpiler 

#### Dependencies 
- Chicken Scheme

	sudo apt-get install chicken
	sudo chicken-install r7rs	 
	sudo chicken-install matchable

#### Supports
- cond			
- case 						
- and 				
- or  				
- when    			
- unless 			
- let     			
- let*    			
- letrec  			
- letrec*  			
- let-values  		
- let*-values 		
- begin  				
- do  				
- delay 			
- delay-force 
- quote
- quasiquote
- unquote
- unquote-splicing
- tail call optimization 

#### Usage 
	wyvern -js <file.scm>
	
This will generate a javascript file out.js in the calling directory. 
Beforewarned, as of now the javascript is very messy, and nearly unreadable.


#### Desugar and Code Gen
Each derived expression will have a corresponding micro-pass that will desugar the expression in terms of core scheme expression. Using pattern-matching, each derived expression is transformed into it's core represention.





##### Future

- [ ] Code clean-up
- [ ] Add more functionality fo Javascript backend.
- [ ] Emit LLVM
