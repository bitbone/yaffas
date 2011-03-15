include ../../../Makefile.common
DESTDIR ?= /
NTROOTDIR=mkntpwd/

install:
	mkdir -p $(DESTDIR)/etc/ldap
	mkdir -p $(DESTDIR)/etc/postfix
	mkdir -p $(DESTDIR)/etc/smbldap-tools
	mkdir -p $(DESTDIR)/etc/ldap/schema
	mkdir -p $(DESTDIR)/tmp
	mkdir -p $(DESTDIR)/$(YAFFAS_BIN)
	cp ldap.conf $(DESTDIR)/etc/
	cp ldap.settings $(DESTDIR)/etc/
	cp nsswitch.conf $(DESTDIR)/etc/
	cp slapd.conf $(DESTDIR)/etc/ldap/
	cp ldap.conf $(DESTDIR)/etc/ldap/
	cp bitkit_base.ldif $(DESTDIR)/tmp/
	cp ldap.secret $(DESTDIR)/etc/
	cp ldap-users.cf $(DESTDIR)/etc/postfix/
	cp ldap-aliases.cf $(DESTDIR)/etc/postfix/
	cp schema/* $(DESTDIR)/etc/ldap/schema/
	cp smbldap* $(DESTDIR)/etc/smbldap-tools/
	cp domrename.pl $(DESTDIR)/$(YAFFAS_BIN)

clean:

