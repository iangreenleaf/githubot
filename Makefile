test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script

test-all:
	./node_modules/.bin/mocha --compilers coffee:coffee-script --recursive

.PHONY: test-all test
