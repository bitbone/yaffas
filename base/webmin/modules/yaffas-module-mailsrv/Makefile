#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=mailsrv

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_BIN)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
	cp -r  bin/* $(DESTDIR)/$(YAFFAS_BIN)/
