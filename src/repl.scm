#!/usr/bin/csi -script

(declare (uses util))
(declare (uses desugar))

(define reader (make-reader))


(define (repl)
		(let* (	(expr (reader)))
			(cond ( (not (eof-object? expr))
				(let ((result-expr (desugar expr))) 
				(display result-expr)(newline)
				(repl))))))
(repl )
;(display "\nGoodbye\n")
