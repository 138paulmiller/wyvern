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
					(if (check-target)
						(cond 
							((string=? (get-target) "-js")
								 (emitjs (list result-expr) #f))
							(else 
								(display usage)))
						(display usage))
					(repl))))))

(define (read-file)
		(let* (	(expr (reader)))
			(if (not (eof-object? expr))
					(append (list  (desugar expr) ) (read-file))
					'())))

(define (emit)
	(if (check-target)
		(let ((exprs (read-file)))
			(cond 
				((string=?  (get-target) "-js")
					 (emitjs exprs outfile))))
		(display usage)))


(if target
	(if is-repl
		(repl)
		(emit))
	(and (display "\nMissing Target Language: \n")(display usage)))
