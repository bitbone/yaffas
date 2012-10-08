#!/usr/bin/make -f
include ../../../../Makefile.common

DESTDIR ?= /
MODULE=security

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_MODULE)
	mkdir -p $(DESTDIR)/$(YAFFAS_DATA)
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/amavis/conf.d
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	
	cp -r $(MODULE) $(DESTDIR)/$(YAFFAS_WEBMIN)/
	cp -r lib/* $(DESTDIR)/$(YAFFAS_MODULE)/

	mkdir -p $(DESTDIR)/etc/amavis/conf.d
	mkdir -p $(DESTDIR)/$(YAFFAS_DATA)/postfix
	cp conf/60-yaffas $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/amavis/conf.d/
	cp conf/60-yaffas-debian $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/amavis/conf.d/
	cp conf/policyd-weight.conf $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	cp conf/amavis-master.cf $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	cp conf/amavisd-redhat.conf $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	cp conf/channels.keys $(DESTDIR)/$(YAFFAS_DATA)/
	cp conf/channels.cf   $(DESTDIR)/$(YAFFAS_DATA)/
	cp -r share/yaffas-module-security $(DESTDIR)/$(YAFFAS_PREFIX)/share
	
