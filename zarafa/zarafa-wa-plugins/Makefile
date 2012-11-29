#!/usr/bin/make -f
include ../../Makefile.common

DESTDIR ?= /

clean:

install:
	mkdir -p $(DESTDIR)/opt/yaffas/zarafa/webaccess/plugins
	cp -a webaccess/passwd $(DESTDIR)/opt/yaffas/zarafa/webaccess/plugins
	mkdir -p $(DESTDIR)/opt/yaffas/zarafa/webapp/plugins
	cp -a webapp/passwd $(DESTDIR)/opt/yaffas/zarafa/webapp/plugins
	mkdir -p $(DESTDIR)/opt/yaffas/share/yaffas-upgrade
	cp -a upgrade/* $(DESTDIR)/opt/yaffas/share/yaffas-upgrade
