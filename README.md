# wyvern
Scheme Transpiler 

#### Dependencies 
Chicken Scheme, with r7rs and mathable extensions

	sudo apt-get install chicken
	sudo chicken-install r7rs	 
	sudo chicken-install matchable

#### Usage 
	wyvern -js <file.scm>
	
This will generate a javascript file out.js in the calling directory. 
Beforewarned, as of now the javascript is very messy, and nearly unreadable.

#### Supports 
Desugaring well tested, could always use more. However, generated Javascript NOT rigoursly tested, backend needs cleaning up first! 
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

##### TODO
- [ ] Convert nested function generation into top-level referenced functions   

##### Future 

- [ ] Code clean-up
- [ ] Add more functionality fo Javascript backend.
- [ ] Emit LLVM
