include ../../Makefile.common
DESTDIR ?= /

INSTALL=cp -rv

clean:

install:
	mkdir -p $(DESTDIR)/opt/software/
	$(INSTALL) software/* $(DESTDIR)/opt/software

.PHONY: all install clean
