SHELL = /bin/bash
SOURCES_COMMON := source/build-logic.txt
SOURCES_DE := de_DE.txt source/de/*.txt $(SOURCES_COMMON)
SOURCES_EN := en_EN.txt source/en/*.txt $(SOURCES_COMMON)
IMAGES := images/en/*.png images/en/yaffas/*.png images/en/zarafa/*.png \
		images/de/yaffas/*.png images/de/*.png
#		  images/de/zarafa/*.png
PRODUCT ?= $(shell echo $(RELEASE) | sed -rne 's:^([^-_]+).*:\1:p')
PRODUCT := $(if $(PRODUCT),$(PRODUCT),yaffas)
VERSION ?= $(shell echo $(RELEASE) | sed -rne 's:^[^-]+-([^_]+).*:\1:p')
VERSION := $(if $(VERSION),$(VERSION),latest)
RELEASE_TYPE ?= $(shell echo $(RELEASE) | sed -rne 's:^[^_]+(_(.*))?:\2:p')
RELEASE_TYPE := $(if $(RELEASE_TYPE),$(RELEASE_TYPE),dev)
A2X_ATTRIBUTES := -a product=$(PRODUCT) -a product-$(PRODUCT) \
		-a release-type=$(RELEASE_TYPE) -a release-type-$(RELEASE_TYPE) \
		-a version=$(VERSION) \
		--stylesheet=styles.css \
		--asciidoc-opts "--conf-file docbook45-linkfix.conf"


HTML_EN := en_EN.html en_EN.chunked 
HTML_DE := de_DE.html de_DE.chunked
HTML_TARGETS := $(HTML_DE)
PDF_TARGETS := de_DE.pdf
ifneq ($(PRODUCT), bitkit)
	HTML_TARGETS := $(HTML_TARGETS) $(HTML_EN) index.html
	PDF_TARGETS := $(PDF_TARGETS) en_EN.pdf
endif

LAST_GIT_CHANGE := $(shell git log -n1 --format="format:%ct" . 2>/dev/null || echo 0)
LAST_LOCAL_CHANGE := $(shell stat --format=%Y index.txt)
LAST_CHANGE := $(shell [[ $(LAST_LOCAL_CHANGE) -gt $(LAST_GIT_CHANGE) ]] && echo $(LAST_LOCAL_CHANGE) || echo $(LAST_GIT_CHANGE))

all: html

html: clean need-thumbs $(HTML_TARGETS)

pdf: clean need-thumbs $(PDF_TARGETS)

need-thumbs: $(IMAGES)
	find images/ -name '*.png' -and -not -name '*_thumb.png' \
		-exec ./bin/build-thumb.sh {} \;

de_DE.html: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fxhtml -dbook de_DE.txt

de_DE.chunked: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fchunked -dbook de_DE.txt
	ln -sf ../docbook-xsl.css de_DE.chunked/
	ln -sf ../styles.css de_DE.chunked/ || true
	# older asciidoc needs the images dir symlinked, newer asciidoc
	# copies the source folder, which is why we need || true
	ln -sf ../images de_DE.chunked 2>/dev/null || true

de_DE.pdf: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) -fpdf de_DE.txt

en_EN.html: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fxhtml -dbook en_EN.txt

en_EN.chunked: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fchunked -dbook en_EN.txt
	ln -sf ../docbook-xsl.css en_EN.chunked/
	ln -sf ../styles.css en_EN.chunked/ || true
	# older asciidoc needs the images dir symlinked, newer asciidoc
	# copies the source folder, which is why we need || true
	ln -sf ../images en_EN.chunked 2>/dev/null || true

en_EN.pdf: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) -fpdf en_EN.txt

index.html: de_DE.html en_EN.html index.txt
	# fix the file's last-changed time, so that asciidoc generates
	# a proper "Last updated" footer
	touch --date=@$(LAST_CHANGE) index.txt >/dev/null 2>&1 || true
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fxhtml -dbook index.txt

clean:
	rm -rf de_DE.pdf de_DE.html en_EN.pdf en_EN.html index.html de_DE.chunked en_EN.chunked
