#!/usr/bin/perl -w

use strict;
use warnings;
use Encode;
use Data::Dumper;
use utf8;

binmode(STDOUT, 'utf8');

# ===============
# = Get options =
# ===============

my($data_file, $wanted_word) = @ARGV;
my $data;
open($data, '<:utf8', $data_file) or die $!;
$wanted_word = decode_utf8($wanted_word);

# =========
# = Count =
# =========

my %bigram_count;
while ( <$data> ) {
	my($left, $right) = split;
	
	#die qq/'$left'   '$right'   '$wanted_word'/;
	
	if ( $left eq $wanted_word ) {
		$bigram_count{qq/$left $right/}++;
	}
}

# =========
# = Print =
# =========

foreach my $bigram ( sort { $bigram_count{$a} <=> $bigram_count{$b} } keys %bigram_count ) {
	print $bigram . ': ' . $bigram_count{$bigram} . "\n";
}