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
const __get_value__  = function(i, value){if(value!=null)return value[i-1];};
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

if(__call__(function(){ 
return __gt__(b, c)})){
	__return__ = __call__(function(){ 
return display(b)});
}
else{
	__return__ = __call__(function(){ 
return display(c)});
};

	return __return__;
});


var tail_call =(function()
{
	var __return__ = null;

	__return__ = __call__(function(){ 
return a(3, __call__(function(){ 
return __add__(8, 8)}))});


	__return__ = __call__(function(){ 
return a(30, __call__(function(){ 
return __add__(8, 8)}))});


	__return__ = __call__(function(){ 
return tail_call()});

	return __return__;
});

__call__(function(){ 
return tail_call()});

