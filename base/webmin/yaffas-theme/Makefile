include ../../../Makefile.common

DESTDIR ?= /

clean:

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)/yui/assets/skins
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)/yaffastheme
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)/images
	cp -a yui/* $(DESTDIR)/$(YAFFAS_WEBMIN)/yui/assets/skins
	cp -a yaffastheme/* $(DESTDIR)/$(YAFFAS_WEBMIN)/yaffastheme
