include ../../Makefile.common
DESTDIR ?= /

INSTALL=cp -rv

clean:

install:
	mkdir -p $(DESTDIR)/opt/software/
	$(INSTALL) software/* $(DESTDIR)/opt/software
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/yaffas-software $(DESTDIR)/$(YAFFAS_PREFIX)/share

.PHONY: all install clean
