# Makefile for creating a deb-Packet for webmin 
# yaffas-samba
#

include ../../../Makefile.common
DESTDIR ?= /
NTROOTDIR=mkntpwd/

INSTALL=cp

SMB_CONF=smb.conf

clean:

install:
	mkdir -p $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/samba
	mkdir -p $(DESTDIR)/tmp
	mkdir -p $(DESTDIR)$(YAFFAS_EXAMPLE)/tmp
	$(INSTALL) -f conf/$(SMB_CONF) $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/samba/smb.conf
	$(INSTALL) -f conf/smbopts.software $(DESTDIR)$(YAFFAS_EXAMPLE)/etc/samba/
	$(INSTALL) -f tmp/root.ldif $(DESTDIR)$(YAFFAS_EXAMPLE)/tmp
	mkdir -p $(DESTDIR)/$(YAFFAS_PREFIX)/share
	cp -r share/yaffas-samba $(DESTDIR)/$(YAFFAS_PREFIX)/share

