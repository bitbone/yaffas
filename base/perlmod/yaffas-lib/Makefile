include ../../../Makefile.common

DESTDIR ?= /

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_PERL)
	mkdir -p $(DESTDIR)/$(YAFFAS_LANG)
	cp -r lib/* $(DESTDIR)/$(YAFFAS_PERL)
	cp -r lang/* $(DESTDIR)/$(YAFFAS_LANG)/

.lang:
	make -C lang/Yaffas/Auth/ .lang
	make -C lang/Yaffas/File/ .lang
	make -C lang/Yaffas/Mail/ .lang
	make -C lang/Yaffas/Postgres/ .lang
	make -C lang/Yaffas/Product/ .lang
	make -C lang/Yaffas/UGM/ .lang
	make -C lang/Yaffas/UI/ .lang
