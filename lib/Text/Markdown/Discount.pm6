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


sub markdown(Str :$str?, Str :$file?, Str :$to-file?) is export
{
    fail "Can't source from both string '$str' and file '$file'"
        if defined $str && defined $file;

    my Text::Markdown::Discount:D $self = do
    {
        with $str { $?PACKAGE.from-str( $str ) }
        else      { $?PACKAGE.from-file($file) }
    };

    with $to-file { $self.to-file($to-file) }
    else          { $self.to-str            }
}


# Compatibility with Text::Markdown
multi method new($text)                      { self.from-str($text)      }
method       render()                        { self.to-str               }
method       to-html()                       { self.to-str               }
method       to_html()                       { self.to_str               }
sub          parse-markdown($text) is export { $?PACKAGE.from-str($text) }
