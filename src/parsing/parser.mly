%{
  open Ltl
%}

%token EOF
%token <bool> BOOL
%token NEXT UNTIL NOT OR AND RELEASE FINALLY GLOBALLY IMPLIES
%token LPAREN RPAREN
%token <string> PROP

%left OR IMPLIES
%left AND
%left UNTIL RELEASE
%left NOT NEXT FINALLY GLOBALLY

%type <Ltl.formula> formula

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
  | FINALLY { Finally }
  | GLOBALLY { Globally }

%inline bop:
  | OR { Or }
  | AND { And }
  | IMPLIES { Implies }
  | UNTIL { Until }
  | RELEASE { Release }

