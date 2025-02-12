version := 0.0.2
package := build/shMate-${version}.tar.gz
testPackage := build/shMate-${version}-test.tar.gz
testResult := build/shMate-${version}-test.xml

.PHONY: all
all: test docs ${package} ${testPackage}

${package}: src/*
	tar --owner 0 --group 0 -C src -czvf ${package} .

${testPackage}: test/*
	tar --owner 0 --group 0 -C test -czvf ${testPackage} .

.PHONY: test
test:
	mkdir -p build
	src/bin/shmate-test -C test > ${testResult}

.PHONY: docs
docs:
	doc/docgen

.PHONY: clean
clean:
	rm -rf build
