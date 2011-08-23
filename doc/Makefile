all: de_DE.html en_EN.html

pdf: de_DE.pdf en_EN.pdf

de_DE.html: de_DE.txt
	asciidoc de_DE.txt

en_EN.html: en_EN.txt
	asciidoc en_EN.txt

de_DE.pdf: de_DE.txt
	a2x de_DE.txt

en_EN.pdf: en_EN.txt
	a2x en_EN.txt

clean:
	rm -f de_DE.pdf de_DE.html en_EN.pdf en_EN.html
