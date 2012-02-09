include ../../../Makefile.common
DESTDIR ?= /

INSTALL=cp -rv

clean:

install:
	mkdir -p $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	$(INSTALL) postfix $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/
	$(INSTALL) saslauthd $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/

.PHONY: all install clean
