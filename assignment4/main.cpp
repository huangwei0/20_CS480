/*
 * Name: Wei Huang
 * Course:cs480
 */

#include <iostream>

#include "ast.hpp"
#include "parser.hpp"

extern int yylex();

extern ASTBlock* programBlock;

int main() {
  if (!yylex()) {
    if (programBlock) {
      std::cout << generateGVSpec(programBlock);
    }
  }
}
