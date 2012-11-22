include ../../../Makefile.common

DESTDIR ?= /

build:

clean:

install:
	mkdir -p "$(DESTDIR)/$(YAFFAS_WEBMIN)/yui"
	cp -r yui/build/* "$(DESTDIR)/$(YAFFAS_WEBMIN)/yui"
	# Fix for ADM-201 (YUI2 bug), introduced for YUI-2.9.0
	find "$(DESTDIR)/$(YAFFAS_WEBMIN)/yui" \
		-name '*.js' -and \
		-not -path '*/selector/selector*.js' \
		-exec sed -re \
			's:(^\s*|[^\.]\s*)(Selector\s*\.\s*):\1YAHOO.util.\2:g' \
			-i {} +
