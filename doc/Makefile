SOURCES_COMMON := source/build-logic.txt
SOURCES_DE := de_DE.txt source/de/*.txt $(SOURCES_COMMON)
SOURCES_EN := en_EN.txt source/en/*.txt $(SOURCES_COMMON)
PRODUCT ?= $(shell echo $(RELEASE) | sed -rne 's:^([^-_]+).*:\1:p')
PRODUCT := $(if $(PRODUCT),$(PRODUCT),yaffas)
VERSION ?= $(shell echo $(RELEASE) | sed -rne 's:^[^-]+-([^_]+).*:\1:p')
VERSION := $(if $(VERSION),$(VERSION),latest)
RELEASE_TYPE ?= $(shell echo $(RELEASE) | sed -rne 's:^[^_]+(_(.*))?:\2:p')
RELEASE_TYPE := $(if $(RELEASE_TYPE),$(RELEASE_TYPE),dev)
A2X_ATTRIBUTES := -a product=$(PRODUCT) -a product-$(PRODUCT) \
		-a release-type=$(RELEASE_TYPE) -a release-type-$(RELEASE_TYPE) \
		-a version=$(VERSION)

TARGETS_EN := en_EN.html en_EN.chunked 
TARGETS_DE := de_DE.html de_DE.chunked
ALL_TARGETS := $(TARGETS_DE)
ifneq ($(PRODUCT), bitkit)
	ALL_TARGETS := $(ALL_TARGETS) $(TARGETS_EN) index.html
endif

LAST_GIT_CHANGE := $(shell git log -n1 --format="format:%ct" . 2>/dev/null || echo 0)
LAST_LOCAL_CHANGE := $(shell stat --format=%Y index.txt)
LAST_CHANGE := $(shell [[ $(LAST_LOCAL_CHANGE) -gt $(LAST_GIT_CHANGE) ]] && echo $(LAST_LOCAL_CHANGE) || echo $(LAST_GIT_CHANGE))

all: clean $(ALL_TARGETS)

pdf: de_DE.pdf en_EN.pdf

de_DE.html: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fxhtml -dbook de_DE.txt

de_DE.chunked: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fchunked -dbook de_DE.txt
	ln -sf ../docbook-xsl.css de_DE.chunked/
	ln -sf ../images de_DE.chunked

de_DE.pdf: $(SOURCES_DE)
	a2x $(A2X_ATTRIBUTES) -fpdf de_DE.txt

en_EN.html: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fxhtml -dbook en_EN.txt

en_EN.chunked: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) --icons-dir=icons -fchunked -dbook en_EN.txt
	ln -sf ../docbook-xsl.css en_EN.chunked/
	ln -sf ../images en_EN.chunked

en_EN.pdf: $(SOURCES_EN)
	a2x $(A2X_ATTRIBUTES) -fpdf en_EN.txt

index.html: de_DE.html en_EN.html index.txt
	# fix the file's last-changed time, so that asciidoc generates
	# a proper "Last updated" footer
	touch --date=@$(LAST_CHANGE) index.txt >/dev/null 2>&1 || true
	asciidoc index.txt

clean:
	rm -rf de_DE.pdf de_DE.html en_EN.pdf en_EN.html index.html de_DE.chunked en_EN.chunked
