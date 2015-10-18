NAME
====

Text::Markdown::Discount - markdown to HTML using the Discount C library

VERSION
=======

0.1.2

SYNOPSIS
========

    use Text::Markdown::Discount;
    my $raw-md = '# Hello `World`!'

    # render HTML into string...
    say markdown($raw-md       ); # from a string
    say markdown('README.md'.IO); # from a file, note the `.IO`

    # ...or directly into files
    markdown($raw-md,        'sample.html');
    markdown('README.md'.IO, 'README.html');

The API from [Text::Markdown](Text::Markdown) is also supported:

    my $md = Text::Markdown::Discount.new($raw-md);
    say $md.render;

    $md = parse-markdown($raw-md);
    say $md.to-html;
    say $md.to_html; # same thing

DESCRIPTION
===========

libmarkdown
-----------

This library provides bindings to the [Discount library](https://github.com/Orc/discount) via [NativeCall](NativeCall). You need to have it installed as the `libmarkdown` shared library.

On Ubuntu 15.04, it's available via `apt-get` as the `libmarkdown2-dev` package, the same goes for several Debians. If it's not available as a binary for your system, you can compile it [from source](https://github.com/Orc/discount).

TODO
====

  * Support for the various flags in Discount

  * Make sure that my NativeCall usage is correct

  * Finish this documentation

AUTHOR
======

Carsten Hartenfels <carsten.hartenfels@googlemail.com>

SEE ALSO
========

[Text::Markdown](Text::Markdown), [Discount](http://www.pell.portland.or.us/~orc/Code/discount/), [Discount GitHub repository](https://github.com/Orc/discount).

COPYRIGHT AND LICENSE
=====================

This software is copyright (c) 2015 by Carsten Hartenfels.

This program is distributed under the terms of the Artistic License 2.0.

For further information, please see LICENSE or visit <http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt>.
