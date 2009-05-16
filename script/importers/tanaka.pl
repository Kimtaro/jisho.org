#!/usr/bin/perl -w

use strict;
use DBI;
use Smart::Comments;
use Encode;
use DateTime;
use Data::Dumper;
use List::MoreUtils;
use File::Basename;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, '..', '..', 'lib')->stringify;
use DenshiJisho::Schema::DJDB;
use DenshiJisho::Lingua;
use DenshiJisho::Importer qw($djdb_schema insert);

# Init
usage() unless $#ARGV >= 0;
binmode(STDOUT, 'utf8');
select STDOUT; $| = 1; # Make unbuffered

my $EXMPL_FILE	= $ARGV[0];
my $examplefh;

#
# Count the number of lines in the data file
#
my $LINES = 0;
open(FILE, $EXMPL_FILE) or die "Can't open `$EXMPL_FILE': $!";
my $buffer;
while (sysread FILE, $buffer, 4096) {
	$LINES += ($buffer =~ tr/\n//);
}
close FILE;

#
# Open for parsing
#
open( $examplefh, "<:utf8", $EXMPL_FILE) || die("Couldn't open example file $EXMPL_FILE: $!");

print "Locking\n";
$djdb_schema->txn_begin;

print "Deleting\n";
$djdb_schema->resultset('Words')->search({source => $TYPE})->delete;

parse($examplefh);

print "Comitting\n";
$djdb_schema->txn_commit;

sub parse {
  printf("%s - Parsing %d lines\n", DateTime->now(), $LINES) if $PRINT_LOG;
  my $i = 1;
  my($words, $japanese, $english, $tanaka_id) = ("" x 4);
  my @lines = (0 .. $LINES);
  for ( @lines ) {	### Parsing [===[%]    ]
  	# We assume that all lines are in order A B. So no checking for that

  	$_ = <$examplefh>;
  	unless (defined $_) {
  		last; # Reached EOF
  	}

  	chomp;

  	if( m/^A:\s (.*?) \#ID=(\d+)$/x ) {
  		($japanese, $english) = split /\t/, $1;
  		$tanaka_id = $2;
  	}
  	elsif( s/^B: // ) {
  		$words = $_;

  	}
  	elsif( /^#/ ) {
  		next;
  	}
  	else {
  		die("Error in file format: $_");
  	}
  }


  close($examplefh);  
}

sub usage {
	print <<EOF;
perl tanaka.pl examples_file
EOF
	exit;
}