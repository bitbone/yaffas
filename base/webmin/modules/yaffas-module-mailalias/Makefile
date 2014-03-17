#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=mailalias
FULL_MODULE=yaffas-module-$(MODULE)

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)
	cp -r  $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r  lib/* $(DESTDIR)/$(YAFFAS_MODULE)/
	cp     libexec/* $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)/
	chmod 755 $(DESTDIR)/$(YAFFAS_LIBEXEC)/$(MODULE)/*
	mkdir -p $(DESTDIR)/$(YAFFAS_SHARE)/$(FULL_MODULE)
	cp share/$(FULL_MODULE)/* $(DESTDIR)/$(YAFFAS_SHARE)/$(FULL_MODULE)
	chmod 755 $(DESTDIR)/$(YAFFAS_SHARE)/$(FULL_MODULE)/*.sh
	mkdir -p $(DESTDIR)/$(YAFFAS_SHARE)/yaffas-upgrade/
	cp share/yaffas-upgrade/* $(DESTDIR)/$(YAFFAS_SHARE)/yaffas-upgrade/
