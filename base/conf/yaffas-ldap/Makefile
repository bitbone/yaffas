include ../../../Makefile.common
DESTDIR ?= /
NTROOTDIR=mkntpwd/

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	mkdir -p $(DESTDIR)/tmp
	mkdir -p $(DESTDIR)/$(YAFFAS_BIN)
	cp -f share/doc/example/etc/ldap.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/nslcd.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/ldap.secret $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/ldap.settings $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/nsswitch.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/$(ETC_LDAP) $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/etc/postfix $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/etc/smbldap-tools $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp yaffas_base.ldif $(DESTDIR)/tmp/
	cp domrename.pl $(DESTDIR)/$(YAFFAS_BIN)

clean:

