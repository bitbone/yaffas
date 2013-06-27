include ../../../Makefile.common

DESTDIR ?= /

clean:

install: 
	mkdir -p $(DESTDIR)/$(YAFFAS_PERL)
	mkdir -p $(DESTDIR)/$(YAFFAS_LANG)
	cp -r lib/* $(DESTDIR)/$(YAFFAS_PERL)
	cp -r lang/* $(DESTDIR)/$(YAFFAS_LANG)/

.lang:
	make -f lang/Yaffas/Auth/Makefile
	make -f lang/Yaffas/File/Makefile
	make -f lang/Yaffas/Mail/Makefile
	make -f lang/Yaffas/Postgres/Makefile
	make -f lang/Yaffas/Product/Makefile
	make -f lang/Yaffas/UGM/Makefile
	make -f lang/Yaffas/UI/Makefile
