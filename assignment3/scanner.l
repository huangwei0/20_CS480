/*
 * Lexer definition for simplified Python syntax.
 */

%{
#include <iostream>
#include <stack>
#include <cstdlib>

#include "parser.hpp"

/*
 * We'll use this stack to keep track of indentation level, as described in
 * the Python docs:
 *
 * https://docs.python.org/3/reference/lexical_analysis.html#indentation
 */
std::stack<int> _indent_stack;
%}

%option noyywrap
%option yylineno

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

  /*
   * We also want to initialize a parser state to be sent to the parser on
   * each push parse call.
   */
  yypstate* pstate = yypstate_new();

  YYSTYPE yylval;
  YYLTYPE loc;

  /*
   * This macro invokes the push parser for a new token.
   */
  #define PUSH_TOKEN(category) do {                         \
    int status = yypush_parse(pstate, category, &yylval, &loc);   \
    if (status != YYPUSH_MORE) {                               \
      yypstate_delete(pstate);                                 \
      return status;                                           \
    }                                                          \
  } while (0)
%}

^[ \t]*\r?\n   { /* Skip blank lines */ }

^[ \t]*#.*\r?\n    { /* Skip whole-line comments. */ }

#.*$        { /* Skip comments on the same line as a statement. */ }

^[ \t]+     {
              /*
               * Handle indentation as described in Python docs linked above.
               * Note that this pattern treats leading spaces and leading tabs
               * equivalently, which could cause some unexpected behavior if
               * they're combined in a single line.  For the purposes of this
               * project, that's OK.
               */
              if (_indent_stack.top() < yyleng) {
                /*
                 * If the current indentation level is greater than the
                 * previous indentation level (stored at the top of the stack),
                 * then emit an INDENT and push the new indentation level onto
                 * the stack.
                 */
                _indent_stack.push(yyleng);
                PUSH_TOKEN(INDENT);
              } else {
                /*
                 * If the current indentation level is less than or equal to
                 * the previous indentation level, pop indentation levels off
                 * the stack until the top is equal to the current indentation
                 * level.  Emit a DEDENT for each element popped from the stack.
                 */
                while (!_indent_stack.empty() && _indent_stack.top() != yyleng) {
                  _indent_stack.pop();
                  PUSH_TOKEN(DEDENT);
                }

                /*
                 * If we popped everythin g off the stack, that means the
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

^[^ \t\n]+  {
              /*
               * If we find a line that's not indented, pop all indentation
               * levels off the stack, and emit a DEDENT for each one.  Then,
               * call REJECT, so the next rule matching this token is also
               * applied.
               */
              while(_indent_stack.top() != 0) {
                _indent_stack.pop();
                PUSH_TOKEN( DEDENT);
              }
              REJECT;
            }

\r?\n       {
              PUSH_TOKEN(NEWLINE);
            }

<<EOF>>     {
              /*
               * If we reach the end of the file, pop all indentation levels
               * off the stack, and emit a DEDENT for each one.
               */
              while(_indent_stack.top() != 0) {
                _indent_stack.pop();
                PUSH_TOKEN(DEDENT);
              }
              int status = yypush_parse(pstate, 0, NULL, NULL);
              yypstate_delete(pstate);
              return status;
            }

[ \t]       { /* Ignore spaces that haven't been handled above. */ }

"and"       { PUSH_TOKEN(AND); }
"break"     { PUSH_TOKEN(BREAK); }
"def"       { PUSH_TOKEN(DEF); }
"elif"      { PUSH_TOKEN(ELIF); }
"else"      { PUSH_TOKEN(ELSE); }
"for"       { PUSH_TOKEN(FOR); }
"if"        { PUSH_TOKEN(IF); }
"not"       { PUSH_TOKEN(NOT); }
"or"        { PUSH_TOKEN(OR); }
"return"    { PUSH_TOKEN(RETURN); }
"while"     { PUSH_TOKEN(WHILE); }

"True"      { PUSH_TOKEN(TRUE); }
"False"     { PUSH_TOKEN(FALSE); }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.str = new std::string(yytext, yyleng);
                          PUSH_TOKEN(IDENTIFIER); }

-?[0-9]*"."[0-9]+       { yylval.str = new std::string(yytext, yyleng);
                          PUSH_TOKEN(FLOAT); }

-?[0-9]+    { yylval.str = new std::string(yytext, yyleng);
              PUSH_TOKEN(FLOAT); }

"="         { PUSH_TOKEN(ASSIGN); }
"+"         { PUSH_TOKEN(PLUS); }
"-"         { PUSH_TOKEN(MINUS); }
"*"         { PUSH_TOKEN(TIMES); }
"/"         { PUSH_TOKEN(DIVIDEDBY); }

"=="        { PUSH_TOKEN(EQ); }
"!="        { PUSH_TOKEN(NEQ); }
">"         { PUSH_TOKEN(GT); }
">="        { PUSH_TOKEN(GTE); }
"<"         { PUSH_TOKEN(LT); }
"<="        { PUSH_TOKEN(LTE); }

"("         { PUSH_TOKEN(LPAREN); }
")"         { PUSH_TOKEN(RPAREN); }

","         { PUSH_TOKEN(COMMA); }
":"         { PUSH_TOKEN(COLON); }

.           {
              std::cerr << "Unrecognized token on line " << yylineno << ": "
                << yytext << std::endl;
              return 1;
            }

%%
