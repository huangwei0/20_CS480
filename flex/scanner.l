%{
  #include <iostream>
  #include <stack> 

std::stack<std::size_t> mystack;
bool begin = true;

%}

%option noyywrap
%option yylineno

%%


%{
  mystack.push(0);

%}


^#.*\n    {/*iginor commet*/}
^[ ]*\r\n { /*This ignores blank new lines specifically in windows*/ }


[1-9][0-9]*  { std::cout << "INTEGER\t\t" <<yytext << std::endl;begin = false;}
[0-9]+("."[0-9]+)? { std::cout << "FLOAT\t\t" << yytext << std::endl; begin = false;}
True    { std::cout << "BOOLEAN\t\t1" << std::endl; begin = false;}
False    { std::cout << "BOOLEAN\t\t0" << std::endl; begin = false;}
and     { std::cout << "AND\t\t" << yytext << std::endl; begin = false;}
break     { std::cout << "BREAK\t\t" << yytext << std::endl; begin = false;}
def     { std::cout << "DEF\t\t" << yytext << std::endl; begin = false;}
elif     { std::cout << "ELIF\t\t" << yytext << std::endl; begin = false;}
else     { std::cout << "ELSE\t\t" << yytext << std::endl;begin = false; }
for     { std::cout << "FOR\t\t" << yytext << std::endl; begin = false;}
if     { std::cout << "IF\t\t" << yytext << std::endl; begin = false;}
not     { std::cout << "NOT\t\t" << yytext << std::endl; begin = false;}
or     { std::cout << "OR\t\t" << yytext << std::endl; begin = false;}
return     { std::cout << "RETURN\t\t" << yytext << std::endl; begin = false;}
while     { std::cout << "WHILE\t\t" << yytext << std::endl;begin = false; }

[a-zA-Z_][0-9a-zA-Z_]*    { std::cout << "IDENTIFIER\t" << yytext << std::endl;begin = false; }


[ \t]*   {
  /*IDENT/ DEDENT function reference from FanKai Yuan, https://github.com/fankaiyuan/CS480/blob/master/assignment-1-fankaiyuan-master/Assignment_1/scanner.l#L18*/
          if(begin){
                  size_t top_len = mystack.top();
                  if(yyleng>top_len){
                        mystack.push(yyleng);
                        std::cout<<"INDENT"<<std::endl;
                  }
                  else if(yyleng<top_len){
                    while(yyleng<top_len){
                          mystack.pop();
                         std::cout<<"DEDENT"<<std::endl;
                          top_len = mystack.top();
                    }
                 }
                begin=false;
         } 
    }

[\n]         {if(begin){
                size_t top_len=mystack.top();
                if(yyleng>top_len){
                    while(yyleng<top_len){
                        mystack.pop();
                        std::cout<<"DEDENT"<<std::endl;
                        top_len=mystack.top();
                    }
                  }
              }
              else{
                std::cout<<"NEWLINE"<<std::endl;
                begin=true;
              }
            }

       
"="     { std::cout << "ASSIGN\t\t" << yytext << std::endl;begin = false;}
"+"     { std::cout << "PLUS\t\t" << yytext << std::endl; begin = false;}
"-"     { std::cout << "MINUS\t\t" << yytext << std::endl; begin = false;}
"*"     { std::cout << "TIMES\t\t" << yytext << std::endl; begin = false;}
"/"     { std::cout << "DIVIDEDBY\t" << yytext << std::endl; begin = false;}
"=="     { std::cout << "EQ\t\t" << yytext << std::endl; begin = false;}
"!="     { std::cout << "NEQ\t\t" << yytext << std::endl; begin = false;}
">="     { std::cout << "GTE\t\t" << yytext << std::endl;begin = false; }
">"     { std::cout << "GT\t\t" << yytext << std::endl; begin = false;}
"<="     { std::cout << "LTE\t\t" << yytext << std::endl; begin = false;}
"<"     { std::cout << "LT\t\t" << yytext << std::endl; begin = false;}
"("     { std::cout << "LPAREN\t\t" << yytext << std::endl; begin = false;}
")"     { std::cout << "RPAREN\t\t" << yytext << std::endl; begin = false;}
","     { std::cout << "COMMA\t\t" << yytext << std::endl;begin = false;}
":"     {  std::cout << "COLON\t\t" << yytext << std::endl;begin = false;}


<<EOF>>       {
                size_t top_len=mystack.top();
                if(yyleng<top_len){
                  while(yyleng<top_len){
                    mystack.pop();
                    top_len = mystack.top();
                  }
                }
                
                return 0;
              }
%%

int main() {
    yylex();
}