[![Build Status](https://travis-ci.org/hartenfels/Text-Markdown-Discount.svg?branch=master)](https://travis-ci.org/hartenfels/Text-Markdown-Discount)

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

The API from [Text::Markdown](https://github.com/retupmoca/p6-markdown/) is also supported:

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

Simple API
----------

### markdown

    sub markdown(    Cool:D $str,  Cool $to-file? --> Cool) is export
    sub markdown(IO::Path:D $file, Cool $to-file? --> Cool) is export

This function is probably enough for most cases. It will either take the markdown from the given `$str` or `$file` and convert it to HTML. If `$to-file` is given, the result will be written to the file at that path and returns `True`. Otherwise returns a `Str` with the HTML in it.

Will throw an exception if there's a problem reading or writing files, or if the markdown can't be converted for some reason.

Object API
----------

### from-str

    method from-str(Cool $str --> Text::Markdown::Discount:D)

Parses the given `$str` as markdown and returns an object you can call HTML conversion methods on.

You can call this method on both a class and an object instance.

### from-file

    method from-file(Cool $file --> Text::Markdown::Discount:D)

As [#from-str](#from-str), except will read the markdown from the given `$file`.

### to-str

    method to-str(Text::Markdown::Discount:D: --> Str)

Converts the markdown in the caller into HTML and returns the result.

### to-file

    method to-file(Text::Markdown::Discount:D: Str $file --> Bool)

Converts the markdown in the caller into HTML and writes the result to the given `$file`. Returns `True` or an appropriate `Failure`.

Text::Markdown Compatibility
----------------------------

These functions exist so that you can use `Text::Markdown::Discount` as a drop-in replacement for [Text::Markdown](https://github.com/retupmoca/p6-markdown/). They just dispatch to existing functions:

### new

### parse-markdown

    multi method new($text)
    sub parse-markdown($text) is export

Dispatch to [#from-str](#from-str).

### render

### to-html

### to_html

    method render()
    method to-html()
    method to_html()

Dispatch to [#to-str](#to-str).

BUGS
====

There's probably some bugs in the NativeCall handling. I'm not sure if the types are specified correctly and if the destructor for the native pointers gets called when it needs to.

There seems to be a bug in Discount's `mkd_generatehtml` function, where it adds excessive `nul`s to the output if it has previously been compiled to a string. Due to that, the [#to-file](#to-file) currently just `spurt`s the string output into the file.

Please report bugs [on GitHub](https://github.com/hartenfels/Text-Markdown-Discount/issues).

TODO
====

  * Support for the various flags in Discount

  * Make sure that my NativeCall usage is correct

  * Appropriate exception classes

  * Finish this documentation

AUTHOR
======

[Carsten Hartenfels](mailto:carsten.hartenfels@googlemail.com)

SEE ALSO
========

[Text::Markdown](https://github.com/retupmoca/p6-markdown/), [Discount](http://www.pell.portland.or.us/~orc/Code/discount/), [Discount GitHub repository](https://github.com/Orc/discount).

COPYRIGHT AND LICENSE
=====================

This software is copyright (c) 2015 by Carsten Hartenfels.

This program is distributed under the terms of the Artistic License 2.0.

For further information, please see LICENSE or visit <http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt>.
