#!/usr/bin/perl -w

use strict;
use warnings;
use lib '../../lib';
use DJDB;
use Data::Dumper;
use utf8;

binmode(STDOUT, 'utf8');

my $out_filename = $ARGV[0];

# =======================
# = Connect to database =
# =======================

my $schema = DJDB->connect('DBI:mysql:database=jisho2;host=localhost;port=3306', 'jisho', '');

$schema->storage->on_connect_do([
	"SET NAMES 'utf8'",
	"SET CHARACTER SET 'utf8'"
]);


# =========================
# = Set up the Result Set =
# =========================

my $main_rs = $schema->resultset('Old::Tanaka')->search();

# ==================
# = Open data file =
# ==================

my $data_file;
open($data_file, '>>:utf8', $out_filename);

# =========
# = Count =
# =========

my $i = 0;
while ( my $example = $main_rs->next ) {
	my @word_pairs;
	my @words;
		
	# Note in the data file which sentence we are working on
	#print $data_file "#" . $example->words . "\n";
	
	# Get words
	foreach my $word ( split(/\s/, $example->words) ) {
		# Clean references and inflections
		$word =~ s/ \[[^]]+\] | {[^}]+} | \([^)]+\) | ~ //gx;
		
		push(@words, $word);
	}
	
	# ==================
	# = Create bigrams =
	# ==================
	
	# Both directions
	if ( 0 ) {
		for ( my $x = 0; $x < scalar(@words); $x++ ) {
			for ( my $y = 0; $y < scalar(@words); $y++ ) {
				next if $x == $y; # We don't want "word1 word1"
			
				push(@word_pairs, $words[$x] . q{ } . $words[$y]);
			}
		}
	}
	
	# Rightward
	if ( 1 ) {
		for ( my $x = 0; $x < scalar(@words); $x++ ) {
			for ( my $y = $x+1; $y < scalar(@words); $y++ ) {			
				push(@word_pairs, $words[$x] . q{ } . $words[$y]);
			}
		}
	}
	
	# Print pairs
	print $data_file "$_\n" foreach (@word_pairs);
	
	print "$i\n" if $i++ % 10000 == 0;
}