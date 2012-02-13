include ../../../Makefile.common
DESTDIR ?= /
ETC=etc
LICENSE=license

all:

clean:

install:
	mkdir -p $(DESTDIR)/tmp
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/zarafa/license
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/apache2/sites-available
	mkdir -p $(DESTDIR)/var/log/zarafa
	cp -a $(wildcard $(ETC)/*.cfg) $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/zarafa/
ifeq ($(YAFFAS_OS), "Ubuntu")
	cp -a $(ETC)/zarafa-webaccess-ssl $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/apache2/sites-available/
endif
ifeq ($(YAFFAS_OS), "Debian")
	cp -a $(ETC)/zarafa-webaccess-ssl $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/apache2/sites-available/
endif
	cp zarafa.te $(DESTDIR)/tmp
