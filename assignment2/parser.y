/*Reference from lecture note:
* https://canvas.oregonstate.edu/courses/1764538/external_tools/130331/ 
*https://docs.google.com/document/d/19LCYNojTimpgpvrZu-pawIj0wfRXKZCKHVapwS2BxUI/edit
*/

%{
#include <iostream>
#include <map>

#include "parser.hpp"

std::map<std::string, float> symbols;
extern int yylex();
bool _error = false;
std::string* programs;

void yyerror(YYLTYPE* loc, const char* err);

%}



%define api.pure full
%define api.push-pull push

/* %define api.value.type {stf:: string*} */
%union{
  std::string* str;
  float value;
  int category;
}

%locations

%token <str> IDENTIFIER FLOAT 
%token <category> ASSIGN PLUS MINUS TIMES DIVIDEDBY EQ NEQ GT GTE LT LTE  LPAREN RPAREN COMMA COLON

%token <category> AND BREAK DEF ELIF ELSE FOR IF NOT OR RETURN WHILE  TRUE FALSE NEWLINE DEDENT INDENT 


%type <str> program statement expression else operation boolean

%left PLUS MINUS
%left TIMES DIVIDEDBY
/* %right */
/* %nonassoc */

%start program

%%

program
    : program statement {$$ = new std::string(*$1 + *$2); programs = $$;delete $1, $2;}
    | statement {$$ = new std::string(*$1); programs = $$;delete $1;}
    ;

statement
    : IDENTIFIER ASSIGN operation NEWLINE { symbols[*$1] = 1; $$ = new std::string(*$1 + " = " + *$3 + ";" + "\n"); delete $1, $3;}
    | IF expression COLON NEWLINE INDENT program DEDENT else{ $$ = new std::string("if ( " + *$2 + " ) {\n" + *$6 + " }\n" + *$8);  delete $2, $6, $8;}
    | WHILE expression COLON NEWLINE INDENT program DEDENT{$$ = new std::string("while ( " + *$2 + " ) {\n" + *$6 + "}\n");  delete $2, $6;}
    | BREAK NEWLINE {$$ = new std::string("break;\n");}
    | error NEWLINE { std::cerr << "Invalid statement" << std::endl; _error = true; }
    ;

else
    : ELSE COLON NEWLINE INDENT program DEDENT {$$ = new std::string("else {\n" + *$5 +"}\n");  delete $5;}
    | ELIF expression COLON NEWLINE INDENT program DEDENT else {$$ = new std::string("else if ( " + *$2 + ") {\n" + *$6 + "}\n"); delete $2, $6;}
    | %empty {$$ = new std::string("");}
    ;

expression
    : LPAREN expression RPAREN {$$ = new std::string( " ( " + *$2 + " ) " ); delete $2;}
    | expression EQ expression {$$ = new std::string(*$1 + " == " + *$3);  delete $1, $3;}
    | expression NEQ expression {$$ = new std::string(*$1 + " != " + *$3); delete $1, $3;}
    | expression GT expression {$$ = new std::string(*$1 + " > " + *$3); delete $1, $3;}
    | expression GTE expression {$$ = new std::string(*$1 + " >= " + *$3); delete $1, $3;}
    | expression LT expression {$$ = new std::string(*$1 + " < " + *$3); delete $1, $3;}
    | expression LTE expression {$$ = new std::string(*$1 + " <= " + *$3); delete $1, $3;}
    | expression AND expression {$$ = new std::string(*$1 + " && " + *$3); delete $1, $3;}
    | expression OR expression {$$ = new std::string(*$1 + " || " + *$3); delete $1, $3;}
    | NOT expression {$$ = new std::string("! " + *$2); delete $2;}
    | FLOAT {$$ = new std::string(*$1); delete $1;}
    | IDENTIFIER {$$ = new std::string(*$1);delete $1;}
    | boolean{$$ = new std::string(*$1); delete $1;}
    ;

operation
    : LPAREN operation RPAREN { $$ = new std::string( " ( " + *$2 + " ) " );delete $2; }
    | operation PLUS operation { $$ = new std::string(*$1 + " + " + *$3); delete $1, $3;}
    | operation MINUS operation { $$ = new std::string(*$1 + " - " + *$3); delete $1, $3;}
    | operation TIMES operation { $$ = new std::string(*$1 + " * " + *$3); delete $1, $3;}
    | operation DIVIDEDBY operation { $$ = new std::string(*$1 + " / " + *$3); delete $1, $3;}
    | IDENTIFIER { $$ = new std::string(*$1); delete $1;} 
    | FLOAT { $$ = new std::string(*$1); delete $1;}
    | boolean
    ;

 boolean
    :  TRUE {$$ = new std::string("true");}
    | FALSE {$$ = new std::string("false");}



%%

void yyerror(YYLTYPE* loc,const char* err){
  std::cerr << "Error: " << err << std::endl;
}
