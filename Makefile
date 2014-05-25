all:	stamp.test

stamp.test:		stamp.check
	touch test/src/_*.am
	cd test/ && make check

stamp.check:		stamp.make
	cd test/ && make check
	: > $@

stamp.make:		stamp.configure
	cd test/ && make
	: > $@

stamp.configure:	test/configure.ac
	cd test/ && ./autogen.sh
	: > $@

scrub:
	for f in test/src/_*.am ; do : > "$$f" ; done
	git clean -d -x -f

clean:
	rm -f stamp.*
