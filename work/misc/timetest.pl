#!/usr/bin/perl -w

use strict;
use Unicode::Japanese;
use Time::HiRes qw( gettimeofday tv_interval );
use Encode;


my $t_start = [gettimeofday];

my $asahi = Unicode::Japanese->new("あさひ");
for( 1 .. 100_000 ) {
	my $temp = $asahi->hira2kata();
}

print "Time for Unicode::Japanese: " . tv_interval( $t_start ) . "\n";


$t_start = [gettimeofday];

$asahi = "あさひ";
# Decode from a UTF8 octet sequence to a UTF8 string
$asahi = decode_utf8($asahi);
for( 1 .. 100_000 ) {
	my $temp = hiraganaToKatakana( $asahi );
}

print "Time for own sub: " . tv_interval( $t_start ) . "\n";


sub hiraganaToKatakana {
	my($hira) = @_;
	my $kata		= "";
	my $iterations	= 0;
	
	while( length($hira) ) {
		# Exit if we seem to be stuck in an infinite loop
		# We should really raise an error here
		last if $iterations++ == 50;
		
		my $char	= substr($hira, 0, 1, "");
		my $ord		= ord $char;
		
		if( $ord >= 12353 and $ord <= 12438 ) {
			$kata .= chr($ord + 96);
		}
		else {
			$kata .= $char;
		}
	}
	
	return $kata;
}