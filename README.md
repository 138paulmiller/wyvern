# wyvern
Scheme Transpiler 

#### Dependencies 
- Chicken Scheme

	sudo apt-get install chicken
	sudo chicken-install r7rs	 
	sudo chicken-install matchable


#### Desugar and Code Gen
Each derived expression will have a corresponding micro-pass that will desugar the expression in terms of core scheme expression. Using pattern-matching, each derived expression is transformed into it's core represention.




##### Future

[ ] Code clean-up
[ ] Add more functionality fo Javascript backend.
[ ] Emit LLVM
