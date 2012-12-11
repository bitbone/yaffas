LAST_GIT_CHANGE := $(shell git log -n1 --format="format:%ct" . 2>/dev/null || echo 0)
LAST_LOCAL_CHANGE := $(shell stat --format=%Y index.txt)
LAST_CHANGE := $(shell [[ $(LAST_LOCAL_CHANGE) -gt $(LAST_GIT_CHANGE) ]] && echo $(LAST_LOCAL_CHANGE) || echo $(LAST_GIT_CHANGE))

all: de_DE.html de_DE.chunked en_EN.html en_EN.chunked index.html

pdf: de_DE.pdf en_EN.pdf

SOURCE_DE := de_DE.txt source/de/*.txt
SOURCE_EN := en_EN.txt source/en/*.txt

de_DE.html: $(SOURCE_DE)
	a2x --icons-dir=icons -fxhtml -dbook de_DE.txt

de_DE.chunked: $(SOURCE_DE)
	a2x --icons-dir=icons -fchunked -dbook de_DE.txt
	ln -sf ../docbook-xsl.css de_DE.chunked/
	ln -sf ../images de_DE.chunked

de_DE.pdf: $(SOURCE_DE)
	a2x -fpdf -lang=de de_DE.txt


en_EN.html: $(SOURCE_EN)
	a2x --icons-dir=icons -fxhtml -dbook en_EN.txt

en_EN.chunked: $(SOURCE_EN)
	a2x --icons-dir=icons -fchunked -dbook en_EN.txt
	ln -sf ../docbook-xsl.css en_EN.chunked/
	ln -sf ../images en_EN.chunked

en_EN.pdf: $(SOURCE_EN)
	a2x -fpdf -lang=en en_EN.txt

index.html: de_DE.html en_EN.html index.txt
	# fix the file's last-changed time, so that asciidoc generates
	# a proper "Last updated" footer
	touch --date=@$(LAST_CHANGE) index.txt >/dev/null 2>&1 || true
	asciidoc index.txt

clean:
	rm -rf de_DE.pdf de_DE.html en_EN.pdf en_EN.html index.html de_DE.chunked en_EN.chunked
