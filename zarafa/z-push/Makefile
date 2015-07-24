#!/usr/bin/make -f
include ../../Makefile.common

DESTDIR ?= /

build:
	# Fix migration script base path; migration script will be unable to find
	# its config otherwise.
	sed -re "s|define\\('ZPUSH_BASE_PATH', \"../src\"\\);|define('ZPUSH_BASE_PATH', dirname(__FILE__) . \"/../\");|" \
			-i z-push/tools/migrate-2.0.x-2.1.0.php

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/z-push/
	cp -a z-push/* $(DESTDIR)/usr/share/z-push/
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/z-push $(DESTDIR)/$(YAFFAS_PREFIX)/share
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share/yaffas-upgrade
	cp -r share/yaffas-upgrade/* $(DESTDIR)/$(YAFFAS_PREFIX)/share/yaffas-upgrade
