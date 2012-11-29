include ../../../Makefile.common


DESTDIR ?= /

dummy:

clean:
	git checkout -f usr/ 2>/dev/null || true
	git clean -f -d usr/ 2>/dev/null || true

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_INIT)
	mkdir -p $(DESTDIR)/$(YAFFAS_CONF)
	mkdir -p $(DESTDIR)/$(YAFFAS_STATE)
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)
	mkdir -p $(DESTDIR)/etc/init.d/
	cp -r etc/webmin $(DESTDIR)/$(YAFFAS_CONF)/
ifeq (,$(filter $(YAFFAS_OS),RedHatEnterpriseServer CentOS))
	cp -r etc/init.d/yaffas.debian $(DESTDIR)/$(YAFFAS_INIT)
else
	cp -r etc/init.d/yaffas $(DESTDIR)/$(YAFFAS_INIT)
endif
	cp -r var/webmin/* $(DESTDIR)/$(YAFFAS_STATE)
	cp -r usr/local/webmin $(DESTDIR)/$(YAFFAS_PREFIX)
