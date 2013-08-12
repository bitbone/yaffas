#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=mailalias

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
	cp     libexec/* $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)/
	chmod 755 $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)/*
