#include <iostream>
#include <set>
#include <map>
#include <vector>
#include <queue>
#include <string>
#include <sstream>
#include "parser.hpp"

extern int yylex();

/*
 * These values are globals defined in the parsing function.
 */

extern std::map<std::string, float> symbols;
extern bool _error;
extern struct AST* root;

/*AST function reference from fankaiyuan, https://github.com/fankaiyuan/CS480/blob/master/assignment-3-fankaiyuan-master/parser.y */

struct AST {
	int ID;
	std::string* value;
	std::vector<struct AST*> child;
};



namespace patch
{
	template < typename T > std::string to_string( const T& n )
	{
		std::ostringstream stm ;
		stm << n ;
		return stm.str() ;
	}
}

/* print the AST node by text */
void print(struct AST *node, struct AST *root, int preLevel){
	int level = preLevel;
	for(int i = 0; i< node->child.size(); ++i){
		if(node->child[i]->value != 0 && node->value != 0){
			std::cout << node->ID <<" -> " << node->child[i]->ID<<";\n"<<node->child[i]->ID<<"[label=\""<< *node->child[i]->value <<"\"];\n" ;
		}	
		print(node->child[i], root, level);
	}	
}

int main() {
  if (!yylex()) {
    	std::cout << "digraph G {\n3 [label=\"Block\"]" << std::endl;
		print(root, root,2);
		std::cout<<"}" << std::endl;
		return 0;
  }else{

  	return 1;
  }
}
