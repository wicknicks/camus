# Dependencies you'll probably need to install to compile this: make, curl, git,
# zip, unzip, patch, java7-jdk | openjdk-7-jdk, maven.

# Release specifics. Note that some of these (VERSION, DESTDIR)
# are required and passed to create_archive.sh as environment variables. That
# script can also pick up some other settings (PREFIX, SYSCONFDIR) to customize
# layout of the installation.
ifndef VERSION
# Note that this is sensitive to this package's version being the first
# <version> tag in the pom.xml
VERSION=$(shell grep version pom.xml | head -n 1 | awk -F'>|<' '{ print $$3 }')
endif

export PACKAGE_TITLE=camus
export FULL_PACKAGE_TITLE=confluent-camus
export PACKAGE_NAME=$(FULL_PACKAGE_TITLE)-$(VERSION)

# Defaults that are likely to vary by platform. These are cleanly separated so
# it should be easy to maintain altered values on platform-specific branches
# when the values aren't overridden by the script invoking the Makefile
DEFAULT_APPLY_PATCHES=yes
DEFAULT_DESTDIR=$(CURDIR)/BUILD/
DEFAULT_PREFIX=$(PACKAGE_NAME)
DEFAULT_SYSCONFDIR=PREFIX/etc/$(PACKAGE_TITLE)


# Whether we should apply patches. This only makes sense for alternate packaging
# systems that know how to apply patches themselves, e.g. Debian.
ifndef APPLY_PATCHES
APPLY_PATCHES=$(DEFAULT_APPLY_PATCHES)
endif

# Install directories
ifndef DESTDIR
DESTDIR=$(DEFAULT_DESTDIR)
endif
# For platform-specific packaging you'll want to override this to a normal
# PREFIX like /usr or /usr/local. Using the PACKAGE_NAME here makes the default
# zip/tgz files use a format like:
#   kafka-version-scalaversion/
#     bin/
#     etc/
#     share/kafka/
ifndef PREFIX
PREFIX=$(DEFAULT_PREFIX)
endif

ifndef SYSCONFDIR
SYSCONFDIR:=$(DEFAULT_SYSCONFDIR)
endif
SYSCONFDIR:=$(subst PREFIX,$(PREFIX),$(SYSCONFDIR))

export APPLY_PATCHES
export VERSION
export DESTDIR
export PREFIX
export SYSCONFDIR

all: install


archive: install
	rm -f $(CURDIR)/$(PACKAGE_NAME).tar.gz && cd $(DESTDIR) && tar -czf $(CURDIR)/$(PACKAGE_NAME).tar.gz $(PREFIX)
	rm -f $(CURDIR)/$(PACKAGE_NAME).zip && cd $(DESTDIR) && zip -r $(CURDIR)/$(PACKAGE_NAME).zip $(PREFIX)

apply-patches: $(wildcard patches/*)
#ifeq ($(APPLY_PATCHES),yes)
#	git reset --hard HEAD
#	cat patches/series | xargs -iPATCH bash -c 'patch -p1 < patches/PATCH'
#endif

build: apply-patches
	mvn install -DskipTests=true


install: build
	./create_archive.sh

clean:
	rm -rf $(DESTDIR)
	rm -rf $(CURDIR)/$(PACKAGE_NAME)*
	rm -rf $(FULL_PACKAGE_TITLE)-$(RPM_VERSION)*rpm
	rm -rf RPM_BUILDING

distclean: clean
	git reset --hard HEAD
	git status --ignored --porcelain | cut -d ' ' -f 2 | xargs rm -rf

test:

.PHONY: clean install
