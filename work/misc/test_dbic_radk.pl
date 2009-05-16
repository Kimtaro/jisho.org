#!/usr/bin/perl -w

use strict;
use lib '../lib';
use DJDB;
use Time::HiRes qw( gettimeofday tv_interval );
use Encode;


# Connect DB
my $schema = DJDB->connect('DBI:mysql:database=jisho;host=localhost;port=3306', 'jisho', '');
$schema->storage->on_connect_do(["SET NAMES 'utf8'"]);


# Search
my $t_start = [gettimeofday];
my @radicals = (38);
my $rs = $schema->resultset('Radk')->search(
	{
		radical_number => \@radicals
	},
	{
		group_by => 'kanji',
		order_by => 'kanji_strokes',
		having => {'count(radical_number)' => {'>' => $#radicals}},
	}
);
print "Time for creation: " . tv_interval( $t_start ) . "\n";


# Bogus execute
$t_start = [gettimeofday];
my $first = $rs->first;
print "Time for getting first: " . tv_interval( $t_start ) . "\n";


# Create the output
$t_start = [gettimeofday];
my $output = '';
my $count = 0;

while ( my $kanji = $rs->next ) {
	$count++;
	my $ord = ord($kanji->kanji);
	$output .= q{<a href="/kanji/details/&#$ord;" class="g}. $kanji->kanji_grade .qq{" >&#$ord;</a> };
}
print "Time for output: " . tv_interval( $t_start ) . "\n";
