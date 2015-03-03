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
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/var/www
	cp -r share/yaffas-zarafa $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/yaffas-upgrade $(DESTDIR)/$(YAFFAS_PREFIX)/share
	
	cp -a $(wildcard $(ETC)/*.cfg) $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/zarafa/
	cp -a var/www/index.html $(DESTDIR)/$(YAFFAS_EXAMPLE)/var/www/
ifeq ($(YAFFAS_OS),Ubuntu)
	cp -a $(ETC)/zarafa-webaccess-ssl $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/apache2/sites-available/
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/php5/apache2/conf.d
	cp -a etc/yaffas-zarafa.ini $(DESTDIR)/etc/php5/apache2/conf.d
endif
ifeq ($(YAFFAS_OS),Debian)
	cp -a $(ETC)/zarafa-webaccess-ssl $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/apache2/sites-available/
endif
	cp zarafa.te $(DESTDIR)/tmp
