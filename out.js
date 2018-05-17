const err = function(msg){ console.log("ERROR"+msg);  };
const display = function(a){ return console.log(a);  };
const __empty_list__ = null;

const quote  = function(a){return [a]; };
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
const __aeq__  = function(a, b){return a==b;};
const __seq__  = function(a, b){return a===b;};
const __eq__  = function(a, b){return _.isEqual(a,b);};
const __eqv__  = function(a, b){return _.isEqual(a,b);};
const and  = function(a, b){if(a&&b) return b; else return false;};
const or  = function(a, b){if(a) return a; else if(b) return b; else return false;};

//JS to HTML Helper

const getElementById = function(a) {return document.getElementById(a);};
const getInnerHTML = function(a) {return a.innerHTML;};
const setInnerHTML = function(a,b) {return a.innerHTML = b;};
const string = String;

const __make_value__  = function(n, value_list){return value_list;};
const __get_value__  = function(i, value){if(value!=null)return value[i-1];};

const __eval_if__  = function(test_thunk, then_thunk, else_thunk)
					{if (test_thunk() != false) 
						return then_thunk(); 
					else 
						return else_thunk();};

//trampoline for functions 
function __call__(func) {
  while(func && typeof func === 'function') {
    func = func()
  }
  return func;
}



var a =(function(b, c)
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return __eval_if__((function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return __gt__(b, c)});

	return __return__;
}), (function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return display(b)});

	return __return__;
}), (function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return display(c)});

	return __return__;
}))});

	return __return__;
});

__call__(function(){ 
return a(3, __call__(function(){ 
return __add__(8, 8)}))});

__call__(function(){ 
return a(30, __call__(function(){ 
return __add__(8, 8)}))});


var tail_call =(function(depth)
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return (function(log)
{
	var __return__ = null;
__call__(function(){ 
return setInnerHTML(log, __call__(function(){ 
return __add__(__call__(function(){ 
return getInnerHTML(log)}), __call__(function(){ 
return string(depth)}))}))});


	__return__ = __call__(function(){ 
return __eval_if__((function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return __gt__(depth, 0)});

	return __return__;
}), (function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return tail_call(__call__(function(){ 
return __sub__(depth, 1)}))});

	return __return__;
}), (function()
{
	var __return__ = null;

	__return__ = false;

	return __return__;
}))});

	return __return__;
})(__call__(function(){ 
return getElementById("log")}))});

	return __return__;
});

__call__(function(){ 
return tail_call(1000)});

