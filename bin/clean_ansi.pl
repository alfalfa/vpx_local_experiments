#!/usr/bin/perl -w
use strict;

my $saved = "";
my $buffer = "";

# autoflushing
select(STDERR);
$| = 1;
select(STDIN);
$| = 1;
select(STDOUT);
$| = 1;

while (read(STDIN, $buffer, 1024) > 0) {
    print $buffer;
    $saved .= $buffer;
    my $idx;
    while (($idx = index($saved, "\n")) >= 0) {
        my $first = substr($saved, 0, $idx);
        $saved = substr($saved, $idx + 1);

        $first =~ s/.*\r//;
	$first =~ s/\033\[K.*//;
        print STDERR $first, "\n";
    }

    $saved =~ s/.*\r//;
}

print STDERR $saved;
