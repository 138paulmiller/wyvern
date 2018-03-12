# wyvern
Scheme to JS/LLVM in Scheme

#### Dependencies 
- Chicken Scheme

	sudo apt-get install chicken
	sudo chicken-install r7rs	 
	sudo chicken-install matchable

- Clang

	sudo apt-get install clang


#### Desugar and Code Gen
Each derived expression will have a corresponding micro-pass that will desugar the expression in terms of core scheme expression. Using matches, each derived expression will be transformed into it's core represented.


##### LLVM Thoughs
Var args and TailCall in LLVM 
https://stackoverflow.com/questions/7015477/llvm-assembly-call-a-function-using-varargs

For (list x1 ...xn) create static references(like strings) and substitute in temp name

(list 1 2 3 4 5 ) = (cons (1 (cons 2 (cons 3 (cons 4 (cons 5 '() ))))))





