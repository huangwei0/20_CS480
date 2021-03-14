/*Reference from lecture note:
* https://canvas.oregonstate.edu/courses/1764538/external_tools/130331/ 
*https://docs.google.com/document/d/19LCYNojTimpgpvrZu-pawIj0wfRXKZCKHVapwS2BxUI/edit
*/

/*
 * Lexer definition for simplified Python syntax.
 */

/*
 * Since we're only parsing 1 file, we don't need to have yywrap() (plus,
 * having it included messes up compilation).
 */
%option noyywrap

%option yylineno

%{
#include <iostream>
#include <stack>
#include <cstdlib>

#include "parser.hpp"


YYSTYPE yylval;
YYLTYPE yylloc;


yypstate* pstate = yypstate_new();


#define PUSH_TOKEN(category) do {  \
  int status = yypush_parse(pstate, category, &yylval, &yylloc);  \
  if (status != YYPUSH_MORE) {                                 \
    yypstate_delete(pstate);                              \
    return status;                                             \
  }                                                       \
} while(0)


/*
 * We'll use this stack to keep track of indentation level, as described in
 * the Python docs:
 *
 * https://docs.python.org/3/reference/lexical_analysis.html#indentation
 */
std::stack<int> _indent_stack;
%}

%%

%{
  /*
   * These lines go at the top of the lexing function.  We only want to
   * initialize the indentation level stack once by pushing a 0 onto it (the
   * indentation stack should never be empty, except immediately after it is
   * created).
   */
  if (_indent_stack.empty()) {
    _indent_stack.push(0);
  }
%}

^[ \t]*\r?\n   { /* Skip blank lines */ }

^[ \t]*#.*\r?\n    { /* Skip whole-line comments. */ }

#.*$          { /* Skip comments on the same line as a statement. */ }

^[ \t]+       {
                /*
                 * Handle indentation as described in Python docs linked above.
                 * Note that this pattern treats leading spaces and leading tabs
                 * equivalently, which could cause some unexpected behavior
                 * (compared to normal Python indentation behavior) if they're
                 * combined in a single line.  For the purposes of this project,
                 * that's OK.
                 */
                if (_indent_stack.top() < yyleng) {
                  /*
                   * If the current indentation level is greater than the
                   * previous indentation level (stored at the top of the stack),
                   * then emit an INDENT and push the new indentation level onto
                   * the stack.
                   */
                  /* std::cout << "INDENT" << std::endl; */
                   PUSH_TOKEN((yylval.category = INDENT));
                   _indent_stack.push(yyleng);
                 } else {
                  /*
                   * If the current indentation level is less than or equal to
                   * the previous indentation level, pop indentation levels off
                   * the stack until the top is equal to the current indentation
                   * level.  Emit a DEDENT for each element popped from the stack.
                   */
                  while (!_indent_stack.empty() && _indent_stack.top() != yyleng) {
                    _indent_stack.pop();
                    /* std::cout << "DEDENT" << std::endl; */
                    PUSH_TOKEN((yylval.category = DEDENT));
                  }

                  /*
                   * If we popped everything off the stack, that means the
                   * current indentation level didn't match any on the stack,
                   * which is an indentation error.
                   */
                  if (_indent_stack.empty()) {
                    std::cerr << "Error: Incorrect indentation on line "
                      << yylineno << std::endl;
                    return 1;
                  }
                }
              }

^[^ \t\r\n]+  {
                /*
                 * If we find a line that's not indented, pop all indentation
                 * levels off the stack, and emit a DEDENT for each one.  Then,
                 * call REJECT, so the next rule matching this token is also
                 * applied.
                 */
                while (_indent_stack.top() != 0) {
                  _indent_stack.pop();
                  /* std::cout << "DEDENT" << std::endl; */
                  PUSH_TOKEN((yylval.category = DEDENT));
                }
                REJECT;
              }

\r?\n         {
                /*
                 * This rule will apply only to endlines that some after a
                 * statement.  Endlines assocuated with empty lines and
                 * comments are handled above.
                 */
                /* std::cout << "NEWLINE" << std::endl; */
                PUSH_TOKEN((yylval.category = NEWLINE));
              }

<<EOF>>       {
                /*
                 * If we reach the end of the file, pop all indentation levels
                 * off the stack, and emit a DEDENT for each one.
                 */
                while(_indent_stack.top() != 0) {
                  _indent_stack.pop();
                  /* std::cout << "DEDENT" << std::endl; */
                  PUSH_TOKEN((yylval.category = DEDENT));
                }
                int status = yypush_parse(pstate, 0, NULL, NULL);
                yypstate_delete(pstate);
                return status;
              }

[ \t]         { /* Ignore spaces that haven't been handled above. */ }

"and"         { /* std::cout << "AND\t\t" << yytext << std::endl;   */
                PUSH_TOKEN((yylval.category = AND));
               }
"break"       { /* std::cout << "BREAK\t\t" << yytext << std::endl; */
                PUSH_TOKEN((yylval.category = BREAK));
               }
"def"         { /* std::cout << "DEF\t\t" << yytext << std::endl;   */
                PUSH_TOKEN((yylval.category = DEF));
               }
"elif"        { /* std::cout << "ELIF\t\t" << yytext << std::endl;  */
                PUSH_TOKEN((yylval.category = ELIF));
               }
"else"        { /* std::cout << "ELSE\t\t" << yytext << std::endl;  */
                PUSH_TOKEN((yylval.category = ELSE));
               }
"for"         { /* std::cout << "FOR\t\t" << yytext << std::endl;   */
                PUSH_TOKEN((yylval.category = FOR));
               }
"if"          { /* std::cout << "IF\t\t" << yytext << std::endl;    */
                PUSH_TOKEN((yylval.category = IF));
               }
"not"         { /* std::cout << "NOT\t\t" << yytext << std::endl;   */
                PUSH_TOKEN((yylval.category = NOT));
               }
"or"          { /* std::cout << "OR\t\t" << yytext << std::endl;    */
                PUSH_TOKEN((yylval.category = OR));
               }
"return"      { /* std::cout << "RETURN\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = RETURN));
               }
"while"       { /* std::cout << "WHILE\t\t" << yytext << std::endl; */
                PUSH_TOKEN((yylval.category = WHILE));
               }

"True"        { /* std::cout << "BOOLEAN\t\t" << true << std::endl; */
                PUSH_TOKEN((yylval.category = TRUE));
               }
"False"       { /* std::cout << "BOOLEAN\t\t" << false << std::endl;*/
                PUSH_TOKEN((yylval.category = FALSE));
               }

[a-zA-Z_][a-zA-Z0-9_]*  {
                         /* std::cout << "IDENTIFIER\t" << yytext << std::endl;*/
                         yylval.str = new std::string(yytext, yyleng);
                         PUSH_TOKEN(IDENTIFIER);
                         }


-?[0-9]*"."[0-9]+       {
                         /* std::cout << "FLOAT\t\t" << atof(yytext) << std::endl; */
                         yylval.str = new std::string(yytext, yyleng);
                         PUSH_TOKEN(FLOAT);
                        }

-?[0-9]+      {
                /* std::cout << "INTEGER\t\t" << atoi(yytext) << std::endl; */
                yylval.str = new std::string(yytext, yyleng);
                         PUSH_TOKEN(FLOAT);
              }

"="           { /* std::cout << "ASSIGN\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = ASSIGN));
              }
"+"           { /* std::cout << "PLUS\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = PLUS));
              }
"-"           { /* std::cout << "MINUS\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = MINUS));
              }
"*"           { /* std::cout << "TIMES\t\t" << yytext << std::endl; */
                PUSH_TOKEN((yylval.category = TIMES));
              }
"/"           { /* std::cout << "DIVIDEDBY\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = DIVIDEDBY));
              }

"=="          { /* std::cout << "EQ\t\t" << yytext << std::endl;*/
               PUSH_TOKEN((yylval.category = EQ));
              }
"!="          { /* std::cout << "NEQ\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = NEQ));
              }
">"           { /* std::cout << "GT\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = GT));
              }
">="          { /* std::cout << "GTE\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = GTE));
              }
"<"           { /* std::cout << "LT\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = LT));
              }
"<="          { /* std::cout << "LTE\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = LTE));
              }

"("           { /* std::cout << "LPAREN\t\t" << yytext << std::endl;*/
               PUSH_TOKEN((yylval.category = LPAREN));
              }

")"           { /*std::cout << "RPAREN\t\t" << yytext << std::endl;*/
               PUSH_TOKEN((yylval.category = RPAREN));
              }

","           { /* std::cout << "COMMA\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = COMMA));
              }
":"           { /* std::cout << "COLON\t\t" << yytext << std::endl;*/
                PUSH_TOKEN((yylval.category = COLON));
              }
.             {
                std::cerr << "Unrecognized token on line " << yylineno << ": "
                  << yytext << std::endl;
                return 1;
              }
%%
