include ../../../Makefile.common

DESTDIR ?= /
VER := 4.0

clean:

install:
	mkdir -p $(DESTDIR)/$(YAFFAS_WEBMIN)/ckeditor
	cp -r ckeditor/* $(DESTDIR)/$(YAFFAS_WEBMIN)/ckeditor

upstream-update:
	git rm -rf ckeditor || true
	wget http://download.cksource.com/CKEditor/CKEditor/CKEditor%20$(VER)/ckeditor_$(VER)_standard.tar.gz -O ckeditor.tar.gz
	tar xvzf ckeditor.tar.gz ckeditor/
	rm -rf ckeditor/samples ckeditor/README* ckeditor/CHANGES*
	rm ckeditor.tar.gz
	sed -re 's|(Version:\s+)\S+|\1'$(VER)'|' -i \
		./redhat/yaffas-ckeditor.spec
	sed -re 's|^(yaffas-ckeditor\s+)\(\S+\)|\1('$(VER)'-1)|' -i \
		./debian/changelog
	git add ckeditor redhat/yaffas-ckeditor.spec debian/changelog
