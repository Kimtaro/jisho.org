#!/usr/bin/perl -w

use strict;
use warnings;
use lib '../lib';
use DJDB;
use Data::Dumper;
use utf8;

binmode(STDOUT, 'utf8');

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

my $main_rs = $schema->resultset('Old::Edict');

# ==========================
# = Fetch all common words =
# ==========================

my $common = $main_rs->search({ is_common => 1 });

# =========
# = Count =
# =========

my %kanji;

while ( my $word = $common->next ) {
	#print $word->kanji . ": " if $word->kanji ne '';
	foreach ( $word->kanji =~ m/(\p{Han})/g ) {
		#print "$_ ";
		$kanji{$_}++;
	}
	#print "\n";
}

# ========
# = Sort =
# ========

print "-- ";
print "Number of kanji: " . scalar(keys(%kanji)) . "\n\n";
print "Kanji,Count\n";

my %count; # This will show how many kanji of each count there is

my $i = 1;
foreach my $key ( sort { $kanji{$b} <=> $kanji{$a} } keys(%kanji) ) {
	print $i++ . ",$kanji{$key}\n";
	#print "$key,$kanji{$key}\n";
	$count{$kanji{$key}}++;
}

print "\n\n-- ";
print "Number of counts: " . scalar(keys(%count)) . "\n\n";
print "Count,Number of kanji with that count\n";

foreach my $key ( sort { $count{$b} <=> $count{$a} } keys(%count) ) {
	print "$key,$count{$key}\n";
}
