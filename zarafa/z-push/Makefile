#!/usr/bin/make -f
include ../../Makefile.common

DESTDIR ?= /

clean:

install:
	mkdir -p $(DESTDIR)/usr/share/z-push/
	cp -a z-push/* $(DESTDIR)/usr/share/z-push/
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/z-push $(DESTDIR)/$(YAFFAS_PREFIX)/share
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share/yaffas-upgrade
	cp -r share/yaffas-upgrade/* $(DESTDIR)/$(YAFFAS_PREFIX)/share/yaffas-upgrade
