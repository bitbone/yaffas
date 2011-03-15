# Makefile for creating a deb-Packet for webmin 
# yaffas-samba
#

INSTALL=cp
OWNER=root
GROUP=root
BINDIR=/

DESTDIR=debian/tmp/

clean:

install: 
	mkdir -p $(DESTDIR)$(BINDIR)/tmp
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/smbprinters/
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/printer/W32ALPHA
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/printer/W32MIPS
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/printer/W32PPC
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/printer/W32X86
	mkdir -p $(DESTDIR)$(BINDIR)/etc/samba/printer/WIN40
	$(INSTALL) conf/smb.conf $(DESTDIR)$(BINDIR)/etc/samba/
	$(INSTALL) conf/smbopts.software $(DESTDIR)$(BINDIR)/etc/samba/
	$(INSTALL) tmp/root.ldif $(DESTDIR)$(BINDIR)/tmp

