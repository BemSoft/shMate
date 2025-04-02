version := 0.0.4
package := build/shMate-${version}.tar.gz
testPackage := build/shMate-${version}-test.tar.gz
testResult := build/shMate-${version}-test.xml

.PHONY: all
all: test docs ${package} ${testPackage}

${package}: src/*
	find -H src -mindepth 1 -maxdepth 1 | sed 's|src/||' | env GZIP=-9 tar -C src --owner 0 --group 0 -T - -czvf ${package}

${testPackage}: test/*
	find -H test -mindepth 1 -maxdepth 1 | sed 's|test/||' | env GZIP=-9 tar -C test --owner 0 --group 0 -T - -czvf ${testPackage}

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
