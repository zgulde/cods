default: singlepage all

singlepage:
	asciidoctor -a build-singlepage index.adoc

HTML_FILES := $(patsubst %.adoc, %.html, $(shell find . -name \*.adoc))

all: $(HTML_FILES)

%.html: %.adoc
	asciidoctor $<

clean:
	rm -f $(shell find . -name \*.html)
