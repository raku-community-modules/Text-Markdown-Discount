test:
	PERL6LIB=lib prove -e raku

authortest:
	AUTHOR_TESTING=1 $(MAKE) test

README.md: lib/Text/Markdown/Discount.rakumod
	echo '[![Build Status](https://travis-ci.org/hartenfels/Text-Markdown-Discount.svg?branch=master)](https://travis-ci.org/hartenfels/Text-Markdown-Discount)'\
	                         > $@
	echo                    >> $@
	raku --doc=Markdown $< >> $@

.PHONY: test authortest
