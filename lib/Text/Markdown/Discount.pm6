unit class Text::Markdown::Discount;
use NativeCall;


class FILE is repr('CPointer')
{
    sub fopen(Str, Str --> FILE)
        is native(Str) { * }

    sub fclose(FILE --> int32)
        is native(Str) { * }

    my $errno := cglobal(Str, 'errno', int32);
    # Don't wanna use `strerror` because it's not thread-safe.


    method open(Str $file, Str $mode --> FILE)
    {
        fopen($file, $mode)
            or fail "Can't fopen '$file' with mode '$mode' (errno $errno)"
    }

    method close()
    {
        fclose(self) == 0 or warn "Error fclosing '{self}' (errno $errno)"
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


    multi method new(Cool :$str! --> MMIOT:D)
    {
        my int32 $bytes = $str.encode('UTF-8').elems;
        return mkd_string(~$str, $bytes, 0);
    }

    multi method new(Cool :$file! --> MMIOT:D)
    {
        my $fh   = FILE.open(~$file, 'r');
        my $self = try mkd_in($fh, 0);
        $fh.close;
        fail $! without $self;
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

    multi method html(MMIOT:D: Str $file --> Bool)
    {
        # mkd_compile(self, 0) or fail "Can't compile markdown";
        # my $fh = FILE.open($file, 'w');
        # mkd_generatehtml(self, $fh);
        # $fh.close;
        #
        # `mkd_generatehtml` is broken for me. If a MMIOT has been
        # compiled to a string before, it throws an excessive '\0'
        # before the newline at the end.

        return spurt $file, self.html ~ "\n";
    }


    # FIXME Does this actually get called?
    method DESTROY
    {
        mkd_cleanup(self);
    }
}


has MMIOT $!mmiot;

submethod BUILD(:$!mmiot) { * }


method from-str(Cool $str --> Text::Markdown::Discount:D)
{
    return $?PACKAGE.new(mmiot => MMIOT.new(:$str));
}

method from-file(Cool $file --> Text::Markdown::Discount:D)
{
    return $?PACKAGE.new(mmiot => MMIOT.new(:$file));
}


method to-str(Text::Markdown::Discount:D: --> Str)
{
    return $!mmiot.html;
}

method to-file(Text::Markdown::Discount:D: Str $file --> Bool)
{
    return $!mmiot.html($file);
}


multi sub markdown(Cool:D $str, Cool $to-file? --> Cool) is export
{
    my $self = $?PACKAGE.from-str($str);
    return $to-file.defined ?? $self.to-file(~$to-file) !! $self.to-str;
}

multi sub markdown(IO::Path:D $file, Cool $to-file? --> Cool) is export
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

The API from L<Text::Markdown|https://github.com/retupmoca/p6-markdown/> is
also supported:

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

=head2 Simple API

=head3 markdown

    sub markdown(    Cool:D $str,  Cool $to-file? --> Cool) is export
    sub markdown(IO::Path:D $file, Cool $to-file? --> Cool) is export

This function is probably enough for most cases. It will either take the
markdown from the given C<$str> or C<$file> and convert it to HTML. If
C<$to-file> is given, the result will be written to the file at that path
and returns C<True>. Otherwise returns a C<Str> with the HTML in it.

Will throw an exception if there's a problem reading or writing files, or if
the markdown can't be converted for some reason.

=head2 Object API

=head3 from-str

    method from-str(Cool $str --> Text::Markdown::Discount:D)

Parses the given C<$str> as markdown and returns an object you can call HTML
conversion methods on.

You can call this method on both a class and an object instance.

=head3 from-file

    method from-file(Cool $file --> Text::Markdown::Discount:D)

As L<#from-str>, except will read the markdown from the given C<$file>.

=head3 to-str

    method to-str(Text::Markdown::Discount:D: --> Str)

Converts the markdown in the caller into HTML and returns the result.

=head3 to-file

    method to-file(Text::Markdown::Discount:D: Str $file --> Bool)

Converts the markdown in the caller into HTML and writes the result to the
given C<$file>. Returns C<True> or an appropriate C<Failure>.

=head2 Text::Markdown Compatibility

These functions exist so that you can use C<Text::Markdown::Discount> as a
drop-in replacement for
L<Text::Markdown|https://github.com/retupmoca/p6-markdown/>. They just dispatch
to existing functions:

=head3 new
=head3 parse-markdown

    multi method new($text)
    sub parse-markdown($text) is export

Dispatch to L<#from-str>.

=head3 render
=head3 to-html
=head3 to_html

    method render()
    method to-html()
    method to_html()

Dispatch to L<#to-str>.

=head1 BUGS

There's probably some bugs in the NativeCall handling. I'm not sure if the
types are specified correctly and if the destructor for the native pointers
gets called when it needs to.

There seems to be a bug in Discount's C<mkd_generatehtml> function, where it
adds excessive C<nul>s to the output if it has previously been compiled to a
string. Due to that, the L<#to-file> currently just C<spurt>s the string
output into the file.

Please report bugs
L<on GitHub|https://github.com/hartenfels/Text-Markdown-Discount/issues>.

=head1 TODO

=item Support for the various flags in Discount
=item Make sure that my NativeCall usage is correct
=item Appropriate exception classes
=item Finish this documentation

=head1 AUTHOR

L<Carsten Hartenfels|mailto:carsten.hartenfels@googlemail.com>

=head1 SEE ALSO

L<Text::Markdown|https://github.com/retupmoca/p6-markdown/>,
L<Discount|http://www.pell.portland.or.us/~orc/Code/discount/>,
L<Discount GitHub repository|https://github.com/Orc/discount>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Carsten Hartenfels.

This program is distributed under the terms of the Artistic License 2.0.

For further information, please see LICENSE or visit
<http://www.perlfoundation.org/attachment/legal/artistic-2_0.txt>.

=end pod
