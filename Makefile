PODMAN?=$(shell command -v podman)
MKOSI_CACHE?=/tmp/mkosi-debinit.cache # Speedup cache
TEST_PHASE?=INITRD_BASIC
WITH_PODMAN?=$(if $(PODMAN),1,0)

.PHONY: tests
tests:
ifeq ($(WITH_PODMAN),0)
	./scripts/$@.sh $(TEST_PHASE)
else
	@mkdir -p /tmp/mkosi-debinit.cache
	$(PODMAN) run --rm --privileged -v /tmp/mkosi-debinit.cache:/tmp/mkosi-debinit.cache -v /var/tmp:/var/tmp -v ${PWD}:/workspace -e MKOSI_CACHE=$(MKOSI_CACHE) --workdir=/workspace docker.io/debian:testing /bin/bash -c "/workspace/scripts/setup.sh build tests && /workspace/scripts/$@.sh $(TEST_PHASE)"
endif

.PHONY: build
build:
ifeq ($(PODMAN),)
	./scripts/$@.sh
else
	$(PODMAN) run --rm -v ${PWD}:/workspace:z --workdir=/workspace docker.io/debian:testing /bin/bash -c "/workspace/scripts/setup.sh $@ && /workspace/scripts/$@.sh"
endif

.PHONY: lint
lint:
ifeq ($(PODMAN),)
	./scripts/$@.sh SHELL DPKG
else
	$(PODMAN) run --rm -v ${PWD}:/workspace:z --workdir=/workspace docker.io/debian:testing /bin/bash -c "/workspace/scripts/setup.sh $@ && /workspace/scripts/$@.sh SHELL DPKG"
endif

setup:
	./scripts/$@.sh

.PHONY: clean
clean:
	rm -rf update-mkosi-debinit.1

.PHONY: dist-clean
dist-clean: clean
	rm -rf dist
	$(MAKE) -f debian/rules clean
