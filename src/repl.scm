#!/usr/bin/csi -script

(declare (uses util))
(declare (uses desugar))
;(declare (uses manip))
(declare (uses emitjs))


(define reader (make-reader))
;Expected usage 
(define usage "wyvern -js <file.scm>")
(define outfile "out.js")

(define (repl)
		(let* (	(expr (reader)))
			(cond ( (not (eof-object? expr))
				(let ((result-expr  (desugar expr))) 
					(cond 
						((string=? target "-js")
							 (emitjs (list result-expr) outfile))
						(else 
							(display usage)))
					(repl))))))

(define (read-file)
		(let* (	(expr (reader)))
			(if (not (eof-object? expr))
					(append (list  (desugar expr)   ) (read-file))
					'()
					)))

(define (emit)
	(cond 
		((string=? target "-js")
			 (emitjs (list (read-file)) outfile))
		(else 
			(display usage))))
(if target
	(if is-repl
		(repl)
		(emit))
	(and (display "\nMissing Target Language: \n")(display usage)))
