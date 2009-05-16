#!/usr/bin/perl -w
#
#  radk.pl
#
#  Imports the radk file into a database
#  and spits out HTML suitable for the
#  search by radical page's radical list.

use strict;
use warnings;
use Data::Dumper;
use utf8;
use File::Basename;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, '..', '..', 'lib')->stringify;
use DenshiJisho::Schema::DJDB;
use DenshiJisho::Lingua;
use DenshiJisho::Importer qw($djdb_schema insert);

# ==============
# = Init stuff =
# ==============

usage() if $#ARGV < 0;
my $FILE = $ARGV[0];
binmode(STDOUT, 'utf8');

if ( $FILE eq 'make_html' ) {
  make_html();
  exit;
}

# ==================================
# = Prepare for inserting new data =
# ==================================

my $filehandle;
open( $filehandle, "<:encoding(eucjp)", $FILE) || die("Couldn't open radk file $FILE: $!");

print "Beginning transaction\n";
$djdb_schema->txn_begin();

print "Deleting\n";
$djdb_schema->resultset('Radicals')->delete;
$djdb_schema->resultset('KanjiRadicals')->delete;

# ==================
# = Parse the file =
# ==================

my $rad_num	= 0;
my($radical, $kanji, $strokes);
while( <$filehandle> ) {
	# Skip comments
	next if /^#/;
	
	# Print the current line being processed
	print;
	
	# Radical line
	if( /^\$ \s ([^\s]*?) \s (\d+)/x ) {
		$radical = $1;
		$strokes = $2;
		$rad_num++;
	
		# Insert in database
		$radical = $djdb_schema->resultset('Radicals')->create({
		  radical => $radical,
			number => $rad_num,
			strokes => $strokes,
		});
		
		next;
	}
	
	# Kanji line, split it up and take them out
	chomp;
	foreach my $kanji (split '') {
		$kanji = $djdb_schema->resultset('Kanji')->find({kanji => $kanji});
		
		# Skip if already in db (duplicates in the radk file)
		next if $djdb_schema->resultset('KanjiRadicals')->count({
		  kanji_id => $kanji->id,
		  radical_id => $radical->id,
		}) > 0;

		insert('INSERT INTO kanji_radicals SET kanji_id = ?, radical_id = ?, kanji_grade = ?, kanji_strokes = ?',
		  $kanji->id,
      $radical->id,
      $kanji->grade,
      $kanji->strokes,
    );
	}
}


# ==================
# = Done importing =
# ==================

print "Committing\n";
$djdb_schema->txn_commit();

close($filehandle);


# ===================================
# = Create HTML list of the radical =
# ===================================

make_html();

sub make_html {
  my %img_for_kanji = (
    '化'  => '2_10',
    '个' => '2_11',
    '并' => '2_15',
    '刈' => '2_22',
    '込' => '3_37',
    '尚' => '3_50',
    '忙' => '3_70',
    '扎' => '3_71',
    '汁' => '3_72',
    '犯' => '3_73',
    '艾' => '3_74',
    '邦' => '3_75',
    '阡' => '3_76',
    '老' => '4_81',
    '杰' => '4_107',
    '礼' => '4_115',
    '疔' => '5_132',
    '禹' => '5_142',
    '初' => '5_146',
    '買' => '5_151',
    '滴' => '11_236',
  );
  my $radicals = $djdb_schema->resultset('Radicals')->search(
  	undef,
  	{
  		order_by => [qw/strokes number/],
  		group_by => 'radical'
  	}
  );

  print qq|<ul class="radical_group">\n|;

  my $current = 0;
  while ( my $rad = $radicals->next ) {
  	if ( $rad->strokes != $current ) {
  		$current = $rad->strokes;
  		print qq|</ul>\n|;
  		print qq|<ul class="radical_group">\n|;
  		print qq|	<li class="number">$current</li>\n|;
  	}

    my $disp = $img_for_kanji{$rad->radical}
      ? '<img src="/static/images/radicals/24/' . $img_for_kanji{$rad->radical} . '.gif" alt="" />'
      : $rad->radical;
  	print qq|	<li class="radical" id="rad_|. $current .qq|_|. $rad->number .qq|">|. $disp .qq|</li>\n|;
  }

  print qq|</ul>\n|; 
}

# =========
# = Usage =
# =========

sub usage {
	print <<EOF;
perl radk.pl radk_file|make_html
  'make_html' will generate HTML for the form.
EOF
	exit;
}