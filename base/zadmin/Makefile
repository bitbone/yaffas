include ../../Makefile.common

DESTDIR=
INSTALL=cp -r

all:

install:
	git describe --all --long > git-revision
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/
	$(INSTALL) git-revision $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc/
