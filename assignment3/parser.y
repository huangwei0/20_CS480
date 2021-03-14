%{
#include <iostream>
#include <set>
#include <map>
#include <vector>

#include "parser.hpp"

extern int yylex();
void yyerror(YYLTYPE* loc, const char* err);
std::string* translate_boolean_str(std::string* boolean_str);

/*
 * Here, target_program is a string that will hold the target program being
 * generated, and symbols is a simple symbol table.
 */
std::string* target_program;
std::map<std::string, float> symbols;

bool _error = false;

int nodeID = 0;
/*AST function reference from fankaiyuan, https://github.com/fankaiyuan/CS480/blob/master/assignment-3-fankaiyuan-master/parser.y */

struct AST {
	int ID;
	std::string* value;
	std::vector<struct AST*> child;
};

struct AST* root = new AST;

AST* newNode(std::string* value, int ID){
  AST* temp = new AST;
  temp->value = value;
  temp->ID = ID;
  return temp;
}

void addChild(struct AST *parent, struct AST *Child){
  parent->child.push_back(Child);
}

%}

/* Enable location tracking. */
%locations



/*
 * Because the lexer can generate more than one token at a time (i.e. DEDENT
 * tokens), we'll use a push parser.
 */
%define api.pure full
%define api.push-pull push

/*
 * These are all of the terminals in our grammar, i.e. the syntactic
 * categories that can be recognized by the lexer.
 */
%union{
  std::string* str;
  float value;
  int category;
  struct AST* block;
}

%token <str> IDENTIFIER
%token <str> FLOAT INTEGER
%token <category> INDENT DEDENT NEWLINE
%token <category> AND BREAK DEF ELIF ELSE FOR IF NOT OR RETURN WHILE
%token <category> ASSIGN PLUS MINUS TIMES DIVIDEDBY
%token <category> EQ NEQ GT GTE LT LTE
%token <category> LPAREN RPAREN COMMA COLON TRUE FALSE

%type <block> program statements statement expression condition else

/*
 * Here, we're defining the precedence of the operators.  The ones that appear
 * later have higher precedence.  All of the operators are left-associative
 * except the "not" operator, which is right-associative.
 */


%left OR
%left AND
%left PLUS MINUS
%left TIMES DIVIDEDBY
%left EQ NEQ GT GTE LT LTE
%right NOT


/*symbol function reference from fankaiyuan, https://github.com/fankaiyuan/CS480/blob/master/assignment-3-fankaiyuan-master/parser.y */

/* This is our goal/start symbol. */
%start program

%%

/*
 * Each of the CFG rules below recognizes a particular program construct in
 * Python and creates a new string containing the corresponding C/C++
 * translation.  Since we're allocating strings as we go, we also free them
 * as we no longer need them.  Specifically, each string is freed after it is
 * combined into a larger string.
 */

/*
 * This is the goal/start symbol.  Once all of the statements in the entire
 * source program are translated, this symbol receives the string containing
 * all of the translations and assigns it to the global target_program, so it
 * can be used outside the parser.
 */
program
  : statements { root = $1; }
  ;

/*
 * The `statements` symbol represents a set of contiguous statements.  It is
 * used to represent the entire program in the rule above and to represent a
 * block of statements in the `block` rule below.  The second production here
 * simply concatenates each new statement's translation into a running
 * translation for the current set of statements.
 */
statements
  : statements statement {addChild($1, $2), $$ = $1; }
  | statement {$$ = newNode(new std::string("Block"),nodeID); addChild($$, $1); nodeID++;}
  ;

/*
 * This is a high-level symbol used to represent an individual statement.
 */
statement
  : IDENTIFIER ASSIGN expression NEWLINE { symbols[*$1] = 1.0; $$ = newNode(new std::string("Assignment"), nodeID); addChild($$, newNode(new std::string("Identifier: " + *$1),nodeID+1)); addChild($$, $3); nodeID = nodeID+2;}
  | IF condition COLON NEWLINE INDENT program DEDENT else{ $$ = newNode(new std::string("IF"), nodeID); addChild($$, $2); addChild($$, $6); addChild($$, $8); nodeID++;}
  | WHILE condition COLON NEWLINE INDENT program DEDENT{$$ = newNode(new std::string("WHILE"), nodeID); addChild($$, $2); addChild($$, $6); nodeID++;}
  | BREAK NEWLINE {$$ = newNode(new std::string("BREAK"), nodeID); nodeID++;}
  ;

/*
 * Symbol representing algebraic expressions.  For most forms of algebraic
 * expression, we generate a translated string that simply concatenates the
 * C++ translations of the operands with the C++ translation of the operator.
 */
expression
  : LPAREN expression RPAREN { $$ = $2; }
  | expression PLUS expression { $$ = newNode(new std::string("PLUS"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++; }
  | expression MINUS expression { $$ = newNode(new std::string("MINUS"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++; }
  | expression TIMES expression { $$ = newNode(new std::string("TIMES"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++; }
  | expression DIVIDEDBY expression { $$ = newNode(new std::string("DIVIDEDBY"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++; }
  | FLOAT { $$ = newNode(new std::string("FLOAT: " + *$1),nodeID);nodeID++; }
  | IDENTIFIER { $$ = newNode(new std::string("Identifier: " + *$1),nodeID);nodeID++; }
  | TRUE{$$ = newNode(new std::string("TRUE"),nodeID);nodeID++;}
  | FALSE{$$ = newNode(new std::string("FALSE"),nodeID);nodeID++;}
  ;

/*
 * This symbol represents a boolean condition, used with an if, elif, or while.
 * The C++ translation of a condition concatenates the C++ translations of its
 * operators with one of the C++ boolean operators && or ||.
 */
condition
  : LPAREN condition RPAREN {$$ = newNode(new std::string(""), nodeID); addChild($$, $2);nodeID++;}
  | condition EQ condition {$$ = newNode(new std::string("EQ"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition NEQ condition {$$ = newNode(new std::string("NEQ"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition GT condition {$$ = newNode(new std::string("GT"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition GTE condition {$$ = newNode(new std::string("GTE"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition LT condition {$$ = newNode(new std::string("LT"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition LTE condition {$$ = newNode(new std::string("LTE"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition AND condition {$$ = newNode(new std::string("AND"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | condition OR condition {$$ = newNode(new std::string("OR"),nodeID); addChild($$, $1); addChild($$, $3);nodeID++;}
  | NOT condition {$$ = newNode(new std::string("NOT"),nodeID); addChild($$, $2);nodeID++;}
  | FLOAT {$$ = newNode(new std::string("float: " + *$1),nodeID);nodeID++;}
  | IDENTIFIER {$$ = newNode(new std::string("identifier: " + *$1),nodeID);nodeID++;}
  | TRUE {$$ = newNode(new std::string("true"),nodeID);nodeID++;}
  | FALSE {$$ = newNode(new std::string("false"),nodeID);nodeID++;}
  ;

else
  : ELSE COLON NEWLINE INDENT program DEDENT {$$ = $5;}
  | ELIF condition COLON NEWLINE INDENT program DEDENT else {newNode(new std::string("ELIF"), nodeID); addChild($$, $2); addChild($$, $6); addChild($$, $8); nodeID++;}
  | %empty {$$ = newNode(NULL, nodeID); nodeID++;}
  ;


%%

/*
 * This is our simple error reporting function.  It prints the line number
 * and text of each error.
 */
void yyerror(YYLTYPE* loc, const char* err) {
  std::cerr << "Error (line " << loc->first_line << "): " << err << std::endl;
}

std::string* translate_boolean_str(std::string* boolean_str) {
  if (*boolean_str == "True") {
    return new std::string("true");
  } else {
    return new std::string("false");
  }
}