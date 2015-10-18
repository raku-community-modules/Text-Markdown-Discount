unit class Text::Markdown::Discount;
use NativeCall;


class FILE is repr('CPointer')
{
    sub fopen(Str, Str --> FILE)
        is native(Str) { * }

    sub fclose(FILE --> int32)
        is native(Str) { * }


    method open(Str $file, Str $mode --> FILE)
    {
        fopen($file, $mode) or fail "Can't fopen '$file' with mode '$mode'"
    }

    method close()
    {
        fclose(self) == 0 or fail "Error fclosing '{self}'"
    }
}


class MMIOT is repr('CPointer')
{
    sub mkd_string(Str, int32, int32 --> MMIOT)
        is native('libmarkdown') { * }

    sub mkd_in(OpaquePointer, int32 --> MMIOT)
        is native('libmarkdown') { * }

    sub mkd_compile(MMIOT, int32 --> int32)
        is native('libmarkdown') { * }

    # XXX This should take a `char**` to write to, but I can't make `Pointer`
    #     dance that way. It's also scary to just write to a `Str` like that.
    sub mkd_document(MMIOT, CArray[Str] --> int32)
        is native('libmarkdown') { * }

    sub mkd_generatehtml(MMIOT, FILE --> int32)
        is native('libmarkdown') { * }

    sub mkd_cleanup(MMIOT)
        is native('libmarkdown') { * }


    multi method new(Str :$str! --> MMIOT:D)
    {
        my int32 $bytes = $str.encode('UTF-8').elems;
        return mkd_string($str, $bytes, 0);
    }

    multi method new(Str :$file! --> MMIOT:D)
    {
        my $fh   = FILE.open($file, 'r');
        my $self = mkd_in($fh, 0);
        $fh.close;
        return $self;
    }


    multi method html(MMIOT:D: --> Str)
    {
        mkd_compile(self, 0) or fail "Can't compile markdown";

        # Need a `char**`.
        my $buf = CArray[Str].new;

        # XXX This writes to `$buf[0]`, which is scary.
        $buf[0] = Str;
        mkd_document(self, $buf);

        return $buf[0];
    }

    multi method html(MMIOT:D: Str $file)
    {
        # mkd_compile(self, 0) or fail "Can't compile markdown";
        # my $fh = FILE.open($file, 'w');
        # mkd_generatehtml(self, $fh);
        # $fh.close;
        #
        # `mkd_generatehtml` is broken for me. If a MMIOT has been
        # compiled to a string before, it throws an excessive '\0'
        # before the newline at the end.

        spurt $file, self.html ~ "\n"
    }


    # FIXME Does this actually get called?
    method DESTROY
    {
        mkd_cleanup(self);
    }
}


has MMIOT $.mmiot;


method from-str(Str $str --> Text::Markdown::Discount:D)
{
    return $?PACKAGE.new(mmiot => MMIOT.new(:$str));
}

method from-file(Str $file --> Text::Markdown::Discount:D)
{
    return $?PACKAGE.new(mmiot => MMIOT.new(:$file));
}


method to-str(Text::Markdown::Discount:D: --> Str)
{
    return $.mmiot.html;
}

method to-file(Text::Markdown::Discount:D: Str $file)
{
    $.mmiot.html($file);
}


multi sub markdown(Str:D $str, Cool $to-file?) is export
{
    my $self = $?PACKAGE.from-str($str);
    return $to-file.defined ?? $self.to-file(~$to-file) !! $self.to-str;
}

multi sub markdown(IO::Path:D $file, Cool $to-file?) is export
{
    my $self = $?PACKAGE.from-file(~$file);
    return $to-file.defined ?? $self.to-file(~$to-file) !! $self.to-str;
}


# Compatibility with Text::Markdown
multi method new($text)                      { self.from-str($text)      }
method       render()                        { self.to-str               }
method       to-html()                       { self.to-str               }
method       to_html()                       { self.to_str               }
sub          parse-markdown($text) is export { $?PACKAGE.from-str($text) }


=begin pod

=head1 NAME

Text::Markdown::Discount - markdown to HTML using the Discount C library

=head1 VERSION

0.1.2

=head1 SYNOPSIS

    use Text::Markdown::Discount;
    my $raw-md = '# Hello `World`!'

    # render HTML into string...
    say markdown($raw-md       ); # from a string
    say markdown('README.md'.IO); # from a file, note the `.IO`

    # ...or directly into files
    markdown($raw-md,        'sample.html');
    markdown('README.md'.IO, 'README.html');

The API from L<Text::Markdown> is also supported:

    my $md = Text::Markdown::Discount.new($raw-md);
    say $md.render;

    $md = parse-markdown($raw-md);
    say $md.to-html;
    say $md.to_html; # same thing

=head1 DESCRIPTION

=head2 libmarkdown

This library provides bindings to the L<Discount
library|https://github.com/Orc/discount> via L<NativeCall>.  You need to
have it installed as the C<libmarkdown> shared library.

On Ubuntu 15.04, it's available via C<apt-get> as the
C<libmarkdown2-dev> package, the same goes for several Debians.  If it's
not available as a binary for your system, you can compile it L<from
source|https://github.com/Orc/discount>.

=head1 TODO

=item Support for the various flags in Discount
=item Make sure that my NativeCall usage is correct
=item Finish this documentation

=head1 AUTHOR

Carsten Hartenfels <carsten.hartenfels@googlemail.com>

=head1 SEE ALSO

L<Text::Markdown>,
L<Discount|http://www.pell.portland.or.us/~orc/Code/discount/>,
L<Discount GitHub repository|https://github.com/Orc/discount>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Carsten Hartenfels.

This program is distributed under the terms of the Artistic License 2.0.

For further information, please see LICENSE or visit
<http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt>.

=end pod
