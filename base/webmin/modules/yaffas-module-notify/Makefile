#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=notify

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_DATA)/base/$(MODULE)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
