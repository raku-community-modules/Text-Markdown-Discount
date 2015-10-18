unit module TextMarkdownDiscountTestBoilerplate;
# This module just defines a bunch of stuff used in the other tests.

# Don't really want to use `File::Temp` just for these tests or write
# my own broken temporary file function. `tmpnam` isn't too unbroken
# either, but it's good enough for these tests.
use NativeCall;
sub tmpnam(Pointer[int8] --> Str) is native(Str) { * }
sub tmpname() is export { tmpnam(Pointer[int8]) } # calls `tmpnam(NULL)`

# This'll resolve to this repository's `t/data` folder.
our $data is export = $?FILE.IO.dirname;


class TestFile
{
    has $.md;
    has $.html;
    has $.from;
    has $.to;

    multi method new(Str $file)
    {
        my $md   = "$data/$file.md";
        my $html = "$data/$file.html";
        self.bless(:$md, :$html, :from(slurp $md), :to(slurp $html))
    }
};

our $simple is export = TestFile.new('simple');
