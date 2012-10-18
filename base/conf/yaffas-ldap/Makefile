include ../../../Makefile.common
DESTDIR ?= /
NTROOTDIR=mkntpwd/

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	mkdir -p $(DESTDIR)/tmp
	mkdir -p $(DESTDIR)/$(YAFFAS_BIN)
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -f share/doc/example/etc/ldap.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/nslcd.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/ldap.secret $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/ldap.settings $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -f share/doc/example/etc/nsswitch.conf $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/$(ETC_LDAP) $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/etc/postfix $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/etc/smbldap-tools $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/doc/example/etc/apparmor.d $(DESTDIR)/$(YAFFAS_EXAMPLE)/etc
	cp -r share/yaffas-ldap $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/yaffas-upgrade $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp yaffas_base.ldif $(DESTDIR)/tmp/
	cp domrename.pl $(DESTDIR)/$(YAFFAS_BIN)

clean:

