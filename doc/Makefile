all: de_DE.html en_EN.html index.html

pdf: de_DE.pdf en_EN.pdf

de_DE.html: de_DE.txt source/de/*.txt
	a2x --icons-dir=icons -fxhtml -dbook de_DE.txt
	a2x --icons-dir=icons -fchunked -dbook de_DE.txt
	ln -sf ../docbook-xsl.css de_DE.chunked/
	ln -sf ../media de_DE.chunked

en_EN.html: en_EN.txt source/en/*.txt
	a2x --icons-dir=icons -fxhtml -dbook en_EN.txt
	a2x --icons-dir=icons -fchunked -dbook en_EN.txt
	ln -sf ../docbook-xsl.css en_EN.chunked/
	ln -sf ../media en_EN.chunked

index.html: index.txt
	asciidoc index.txt

de_DE.pdf: de_DE.txt
	a2x -fpdf de_DE.txt

en_EN.pdf: en_EN.txt
	a2x -fpdf en_EN.txt

clean:
	rm -rf de_DE.pdf de_DE.html en_EN.pdf en_EN.html index.html de_DE.chunked en_EN.chunked
