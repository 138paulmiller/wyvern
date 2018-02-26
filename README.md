# wyvern
Scheme to LLVM in Scheme

#### Dependencies 
- Chicken Scheme


	sudo apt-get install chicken
	sudo chicken-install r7rs	 
	sudo chicken-install matchable


#### Desugar and Code Gen
Each derived expression will have a corresponding micro-pass that wil desugar the parse-tree. Using matches, each derived expression will be transformed into it's core represented.


