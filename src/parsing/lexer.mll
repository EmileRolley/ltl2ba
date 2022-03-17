{
  open Lexing
  open Parser

  exception Syntax_error of string

  let next_line lexbuf =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <-
      { pos with pos_bol = lexbuf.lex_curr_pos; pos_lnum = pos.pos_lnum + 1 }

  let startpos = ref 0
}

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let digit = ['0'-'9']
let low_letter = ['a'-'z']
let up_letter = ['A'-'Z']
let not_low_letter = [^'a'-'z']
let id = low_letter (low_letter | up_letter | digit)*

rule read = parse
  | white { read lexbuf }
  | newline { next_line lexbuf; read lexbuf }
  | "NOT" | "not" | "!" { NOT }
  | "X" { NEXT }
  | "U" { UNTIL }
  | "|" { OR }
  | "&" { AND }
  | "(" { LPAREN }
  | ")" { LPAREN }
  | "true" { TRUE }
  | "false" { FALSE }
  | id as i { PROP(i) }
  | eof { EOF }
  | _ {
    let errbuf = Buffer.create 80 in
    startpos := lexbuf.lex_curr_pos;
    Buffer.add_string errbuf (Lexing.lexeme lexbuf);
    get_unmatched_word  errbuf lexbuf
  }

and get_unmatched_word errbuf = parse
  | white | newline | eof {
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <-
      { pos with pos_cnum = !startpos
      };
    raise ( Syntax_error ("Unknown keyword: '" ^ Buffer.contents errbuf ^ "'"))
  }
  | _  {
    Buffer.add_string errbuf (Lexing.lexeme lexbuf);
    get_unmatched_word errbuf lexbuf
  }
