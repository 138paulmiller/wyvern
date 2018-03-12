const err = function(msg){ console.log("ERROR"+msg);  };
const display = function(a){ return console.log(a);  };
const __empty_list__ = null;
const cons  = function(a, b){var l = [a]; if(b != null) l = l.concat(b); return l;};
const car  = function(a){if(a==__empty_list__) return err("Cannot car empty list"); else return a[0];};
const cdr  = function(a){if(a==__empty_list__) return err("Cannot cdr empty list"); else return a.splice(1);};

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
const and  = function(a, b){if(a&&b) return b; else return false;};
const or  = function(a, b){if(a) return a; else if(b) return b; else return false;};

const __make_value__  = function(n, value_list){return value_list;};
const __get_value__  = function(i, value){return value[i-1];};
 
(function(__value_t__)
{
	var __return__ = null;

	__return__ = 
(function(a, b)
{
	var __return__ = null;

	__return__ = 
(function(__value_t__)
{
	var __return__ = null;

	__return__ = 
(function(c, d, e)
{
	var __return__ = null;

	__return__ = display( __mul__(c, d));

	return __return__;
})( __get_value__(1, __value_t__),  __get_value__(2, __value_t__),  __get_value__(3, __value_t__));

	return __return__;
})( __make_value__(3,  cons(a,  cons(b,  cons(3, __empty_list__)))));

	return __return__;
})( __get_value__(1, __value_t__),  __get_value__(2, __value_t__));

	return __return__;
})( __make_value__(2,  cons(3,  cons(4, __empty_list__))));

