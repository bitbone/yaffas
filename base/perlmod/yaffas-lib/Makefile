include ../../../Makefile.common

DESTDIR ?= /

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_PERL)
	mkdir -p $(DESTDIR)/$(YAFFAS_LANG)
	cp -r lib/* $(DESTDIR)/$(YAFFAS_PERL)
	cp -r lang/* $(DESTDIR)/$(YAFFAS_LANG)/
