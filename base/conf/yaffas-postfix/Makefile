include ../../../Makefile.common
DESTDIR ?= /

INSTALL=cp -rv

clean:

install:
	mkdir -p $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	$(INSTALL) postfix $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/yaffas-postfix $(DESTDIR)/$(YAFFAS_PREFIX)/share

.PHONY: all install clean
