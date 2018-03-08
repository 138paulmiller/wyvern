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


