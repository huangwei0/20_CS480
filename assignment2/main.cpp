/*Reference from lecture note:
* https://canvas.oregonstate.edu/courses/1764538/external_tools/130331/ 
*https://docs.google.com/document/d/19LCYNojTimpgpvrZu-pawIj0wfRXKZCKHVapwS2BxUI/edit
*/
#include <iostream>
#include <map>

extern int yylex();
extern std::map<std::string, float> symbols;
extern bool _error;
extern std::string* programs;

int main(int argc, char const *argv[]) {
  if (!yylex() && !_error) {
   std::cout << "#include <iostream>\nint main(){" << std::endl;
   std::map<std::string, float>::iterator it;
   for (it = symbols.begin(); it != symbols.end(); it++) {
     std::cout << "double " << it->first << ";" << std::endl;
   }
   std::cout << "\n" << "/* Begin program */" << "\n" << std::endl;
   std::cout << *programs << std::endl;
   std::cout << "\n" << "/* End program */" << "\n" << std::endl;
   for (it = symbols.begin(); it != symbols.end(); it++) {
     std::cout << "std::cout << \"" << it->first << ": \" << " << it->first << " << std::endl;" << std::endl;
   }
   std::cout << "}" << std::endl;
   return 0;
 } else {
   return 1;
 }
}
