version := 0.0.12
buildDir := build
uberLib := ${buildDir}/shMate-${version}-lib.sh
package := ${buildDir}/shMate-${version}.tar.gz
testPackage := ${buildDir}/shMate-${version}-test.tar.gz
testResult := ${buildDir}/shMate-${version}-test.xml

# The order is important
uberLibSources := \
	src/lib/shmate/_deprecated.sh \
	src/lib/shmate/base.sh \
	src/lib/shmate/assert.sh \
	src/lib/shmate/workdir.sh \
	src/lib/shmate/job.sh \
	src/lib/shmate/dependency.sh
packageSources := $(shell find 'src' -type f)
testPackageSources := $(shell find 'test' -type f)

.PHONY: all
all: clean test docs lib pkg testPkg

.PHONY: pkg
pkg: ${package}

${package}: ${packageSources}
	find -H src -mindepth 1 -maxdepth 1 | sed 's|src/||' | env GZIP=-9 tar -C src --owner 0 --group 0 -T - -czvf ${package}

.PHONY: testPkg
testPkg: ${testPackage}

${testPackage}: ${testPackageSources}
	find -H test -mindepth 1 -maxdepth 1 | sed 's|test/||' | env GZIP=-9 tar -C test --owner 0 --group 0 -T - -czvf ${testPackage}

.PHONY: lib
lib: ${uberLib}

${uberLib}: ${uberLibSources}
	mkdir -p ${buildDir}
	{ \
		printf '%s\n\n' '#!/usr/bin/env bash'; \
		for source in ${uberLibSources}; do \
			sed -E \
				-e '1{/^#!/d;}' \
				-e '/shellcheck source=/d' \
				-e '/^[[:space:]]*\.[[:space:]]+.*[^[:alnum:]]SHMATE_LIB_DIR[^[:alnum:]].*$$/d' "$${source}"; \
			printf '\n'; \
		done; \
	} > "$@"

.PHONY: test
test:
	mkdir -p ${buildDir}
	env CI_SERVER_HOST=localhost src/bin/shmate-test -C test > ${testResult}

.PHONY: docs
docs:
	doc/docgen

.PHONY: clean
clean:
	rm -rf ${buildDir}
