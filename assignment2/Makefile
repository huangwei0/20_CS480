all: parser

# scan: main.cpp scanner.cpp
# 	g++ main.cpp scanner.cpp -o scan

scanner.cpp: scanner.l
	flex -o scanner.cpp scanner.l

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

parser: main.cpp parser.cpp scanner.cpp
	g++ main.cpp parser.cpp scanner.cpp -o parser	


clean:
	rm -f parser scanner.cpp parser.cpp parser.hpp 

