PODMAN?=$(shell command -v podman)
MKOSI_CACHE?=/tmp/mkosi-debinit.cache # Speedup cache
TEST_PHASE?=INITRD_BASIC

.PHONY: tests
tests:
ifeq ($(PODMAN),)
	$(error podman is missing)
else
	@mkdir -p /tmp/mkosi-debinit.cache
	$(PODMAN) run --rm --privileged -v /tmp/mkosi-debinit.cache:/tmp/mkosi-debinit.cache -v /var/tmp:/var/tmp -v ${PWD}:/workspace -e MKOSI_CACHE=$(MKOSI_CACHE) --workdir=/workspace docker.io/debian:testing /usr/bin/bash /workspace/scripts/$@.sh DEPS $(TEST_PHASE)
endif

.PHONY: build
build:
ifeq ($(PODMAN),)
	$(error podman is missing)
else
	$(PODMAN) run --rm -v ${PWD}:/workspace:z --workdir=/workspace docker.io/debian:testing /usr/bin/bash /workspace/scripts/$@.sh
endif


.PHONY: clean
clean:
	rm -rf update-mkosi-debinit.1

.PHONY: dist-clean
dist-clean: clean
	rm -rf dist
	$(MAKE) -f debian/rules clean
