#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=fetchmail

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_CONF)/$(MODULE)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  config/* $(DESTDIR)/$(YAFFAS_CONF)/$(MODULE)
