#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=netconf

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
