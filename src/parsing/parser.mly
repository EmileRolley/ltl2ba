%{
  open Ast
%}

%token EOF
%token TRUE FALSE
%token NEXT UNTIL NOT OR AND
%token LPAREN RPAREN
%token <string> PROP

%type <Ast.formula> formula

%start formula

%%

formula: FALSE EOF { Until (Bool false, Or (Bool false, Not (Bool true))) }
