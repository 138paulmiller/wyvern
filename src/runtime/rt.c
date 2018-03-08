typedef enum Tag{ VOID, INT, BOOLEAN, CLOSURE, CELL, ENV } Tag ;
typedef struct Value (*Lambda)()  ;

typedef struct Value {
  enum Tag tag;
  union{
    struct Int num_int;
    struct Int num_float;
    unsigned int bool;
    struct Closure closure;
    struct Cell cell ;    
  }
} Value;

typedef struct Closure {
  Lambda lambda;
  End* env ;
}Closure;

typedef struct Cell {
  Value* car; 
  Value* cdr; 
}Cell;

typedef struct Env {
  Value* defs; 
  unsigned int len; 
}Env;

static Value make_primitive(Lambda lambda) {
  Value v ;
  v.tag = CLOSURE ;
  v.closure.lambda = lambda ;
  v.closure.env = NULL;
  return v ;
}

static Value make_closure(Lambda lambda, Env env) {
  Value v ;
  v.tag = CLOSURE ;
  v.closure.lambda = lambda ;
  v.closure.env = env ;
  return v ;
}

static Value make_int(int n) {
  Value v ;
  v.tag = INT;
  v.num_int = n ;
  return v ;
}

static Value make_bool(unsigned int b) {
  Value v ;
  v.tag = BOOLEAN ;
  v.bool = b ;
  return v ;
}

static Value make_env(void* env) {
  Value v ;
  v.tag = ENV ;
  v.env.env = env ;
  return v ;
}

static Value cons_cell(Value cons) {
  Value v ;
  v.tag = CELL;
  v.cell.car = malloc(sizeof(Value)) ;
  *v.cell.car = cons  ;
  return v ;
}


Env* make_env_1(Value x) {
  Env* env = malloc(sizeof(Env));
  env->len = 2;
  env->defs[0] = x;
  return t;

}
Value f_1(Env* env, Value a, Value b ) {
  //x = env index 0
  //a = args 0
  //b = args 1
  Value t = mul(a, b);  
  Value t = mul(t, env->defs[0]); 
  return t;
}

int main(){
//To be generated
/*
(define x 10)
(define func
  (lambda (a b)
    (* (* a b) x)))

*/


  Value x;
  x.num_int = 10;
  Value func;
  func.closure = make_closure(lambda_k,make_env_1(x))

 
}