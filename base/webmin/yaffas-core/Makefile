include ../../../Makefile.common


DESTDIR ?= /

clean:

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_INIT)
	mkdir -p $(DESTDIR)/$(YAFFAS_CONF)
	mkdir -p $(DESTDIR)/$(YAFFAS_STATE)
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/etc/init.d/
	cp -r etc/webmin $(DESTDIR)/$(YAFFAS_CONF)/
	cp -r etc/init.d/yaffas $(DESTDIR)/$(YAFFAS_INIT)
	cp -r var/webmin/* $(DESTDIR)/$(YAFFAS_STATE)
	cp -r usr/local/webmin $(DESTDIR)/$(YAFFAS_PREFIX)
