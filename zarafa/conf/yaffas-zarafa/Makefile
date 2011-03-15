DESTDIR=
ETC=etc
LICENSE=license

all:

clean:

install:
	mkdir -p $(DESTDIR)/etc/zarafa/license
	mkdir -p $(DESTDIR)/etc/apache2/sites-available
	mkdir -p $(DESTDIR)/var/log/zarafa
	cp -a $(wildcard $(ETC)/*.cfg) $(DESTDIR)/etc/zarafa/
	cp -a $(ETC)/zarafa-webaccess-ssl $(DESTDIR)/etc/apache2/sites-available/
