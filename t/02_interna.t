use v6;
use Test;
use Text::Markdown::Discount;
use NativeCall;


sub tmpnam(Pointer[int8] --> Str) is native(Str) { * }
sub tmpname() { tmpnam(Pointer[int8]) }
my $t = "{$?FILE.IO.dirname}/data";


class TestFile
{
    has $.md;
    has $.html;
    has $.from;
    has $.to;

    multi method new(Str $file)
    {
        my $md   = "$t/$file.md";
        my $html = "$t/$file.html";
        self.bless(:$md, :$html, :from(slurp $md), :to(slurp $html))
    }
};

my $simple = TestFile.new('simple');


sub test-outputs(Text::Markdown::Discount:D $markdown)
{
    is $markdown.to-str, $simple.to.trim, '...conversion to string works';

    my $file = tmpname;
    $markdown.to-file($file);
    is slurp($file), $simple.to, '...writing to file works';
    unlink $file;
}


{
    my $markdown = Text::Markdown::Discount.from-str($simple.from);
    ok $markdown ~~ Text::Markdown::Discount:D, 'string gets parsed';
    test-outputs($markdown);
}


{
    my $markdown = Text::Markdown::Discount.from-file($simple.md);
    ok $markdown ~~ Text::Markdown::Discount:D, 'file gets parsed';
    test-outputs($markdown);
}

dies-ok { Text::Markdown::Discount.from-file("$t/nonexistent.md") },
        'sourcing from nonexistent file fails';


done-testing
