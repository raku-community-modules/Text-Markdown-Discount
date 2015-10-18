test:
	PERL6LIB=lib prove -e perl6

README.md: lib/Text/Markdown/Discount.pm6
	perl6 --doc=Markdown $< > $@

.PHONY: test
