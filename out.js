
const __add__ = function(a, b){return a+b;};
const __sub__ = function(a, b){return a-b;};
const __mul__ = function(a, b){return a*b;};
const __div__ = function(a, b){return a/b;};
const __lt__  = function(a, b){return a<b;};
const __lte__  = function(a, b){return a<=b;};
const __gt__  = function(a, b){return a>b;};
const __gte__  = function(a, b){return a>=b;};
const __ate__  = function(a, b){return a==b;};
const __ste__  = function(a, b){return a===b;};
const __eq__  = function(a, b){return _.isEqual(a,b);};
const __eqv__  = function(a, b){return _.isEqual(a,b);};
const display  = function(a){return console.log(a);};
 
(function(b, c)
{
	var __return__ = null;

	__return__ = __mul__(b, c);

	return __return__;
})
(3,  __add__(8, 8));

 
(function(b, c)
{
	var __return__ = null;

if( __gt__(b, c)){
	__return__ = display(b);
}
else{
	__return__ = display(c);
};

	return __return__;
})
(3,  __add__(8, 8));

