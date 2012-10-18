#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=setup

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)
	mkdir -p $(DESTDIR)/usr/local/bin
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
	cp -r  example/* $(DESTDIR)/$(YAFFAS_EXAMPLE)/
	cp postinst-all.sh $(DESTDIR)/usr/local/bin
	