default: all

scanner: scanner.l
	flex -o scanner.cpp scanner.l

main: scanner.cpp
	g++ scanner.cpp -o scanner

all: scanner main

test: clean all
	./scanner < testing_code/p1.py 

	./scanner < testing_code/p2.py 

	./scanner < testing_code/p3.py 

	./scanner < testing_code/p4.py 


clean:
	rm -f scanner
	rm -f scanner.cpp
	rm -f *.out
