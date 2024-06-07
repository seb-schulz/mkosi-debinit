PODMAN?=$(shell command -v podman)
MKOSI_CACHE?=/tmp/mkosi-debinit.cache # Speedup cache
TEST_PHASE?=INITRD_BASIC

.PHONY: tests
tests:
ifeq ($(PODMAN),)
	$(error podman is missing)
else
	@mkdir -p /tmp/mkosi-debinit.cache
	$(PODMAN) run --privileged -v /tmp/mkosi-debinit.cache:/tmp/mkosi-debinit.cache -v /var/tmp:/var/tmp -v ${PWD}:/workspace -e MKOSI_CACHE=$(MKOSI_CACHE) --workdir=/workspace docker.io/debian:testing /usr/bin/bash /workspace/tests.sh DEPS $(TEST_PHASE)
endif
