all:	stamp.check

stamp.check:		stamp.make
	cd test/ && make check
        : > $@

stamp.make:		stamp.configure
	cd test/ && make
        : > $@

stamp.configure:	test/configure.ac
	cd test/ && ./autogen.sh
        : > $@

clean:
	rm -f *.stamp
