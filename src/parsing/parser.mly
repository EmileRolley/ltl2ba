%{
  open Ast
%}

%token EOF
%token <bool> BOOL
%token NEXT UNTIL NOT OR AND
%token LPAREN RPAREN
%token <string> PROP

%left OR AND
%left UNTIL
%left NOT NEXT

%type <Ast.formula> formula

%start formula

%%

formula: f = ltl EOF { f }

ltl:
  | b = BOOL { Bool (b) }
  | p = PROP { Prop (p) }
  | o = uop; f = ltl { Uop (o, f) }
  | f = ltl; o = bop; f2 = ltl { Bop (f, o, f2) }
  | LPAREN; f = ltl; RPAREN { f }

%inline uop:
  | NOT { Not }
  | NEXT { Next }

%inline bop:
  | OR { Or }
  | AND { And }
  | UNTIL { Until }

