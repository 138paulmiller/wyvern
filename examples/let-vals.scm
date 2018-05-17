(let-values (
	((a b) (values 3 4) )
	((c d e) (values 1 2 3) )) 
	(display ( *  a b) )
	(display ( *  c d) ))
;comments here

(let*-values (
	((a b) (values 3 4) )
	((c d e) (values a b 3) )) 
	(display ( *  c d ) ))

