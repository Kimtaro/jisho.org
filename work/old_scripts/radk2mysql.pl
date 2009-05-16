#!/usr/bin/perl -w
#
#  radk2mysql.pl
#
#  Converts the radk file to an sql table

package CDBI;

use strict;
use base 'Class::DBI::mysql';
use Class::DBI::Loader::Relationship;

__PACKAGE__->set_db('Main', 'DBI:mysql:database=jisho;host=localhost;port=3306', 'jisho', '');

__PACKAGE__->set_sql(utf8   => qq{ SET NAMES 'utf8' });
__PACKAGE__->set_sql(utf8_2 => qq{ SET CHARACTER SET 'utf8' });

sub utf8 {
	my $class = shift;
	my $sth = $class->sql_utf8;
	$sth->execute;
	#return $class->sth_to_objects($sth);
}

sub utf8_2 {
	my $class = shift;
	my $sth = $class->sql_utf8_2;
	$sth->execute;
	#return $class->sth_to_objects($sth);
}

__PACKAGE__->utf8();
__PACKAGE__->utf8_2();

package CDBI::Kanji;
use base 'CDBI';
__PACKAGE__->set_up_table('kanji');

package CDBI::Stroke_count;
use base 'CDBI';
__PACKAGE__->set_up_table('kanji_stroke_count');

package Main;

use strict;
use DBI;
use utf8;
use Data::Dumper;

binmode(STDOUT, 'utf8');

usage() unless $#ARGV >= 1;

my $DATABASE	= "jisho";
my $LOGIN		= "jisho";
my $PASSWD		= "";
my $FILE		= $ARGV[0];
my $TABLE_NAME	= $ARGV[1];
my $sth;
my $filehandle;

# Connect to databse
my $dbh = DBI->connect("DBI:mysql:database=$DATABASE;host=localhost;port=3306", $LOGIN, $PASSWD);

# Use utf8
{
	$sth = $dbh->prepare("SET NAMES 'utf8'");
	$sth->execute;
	$sth = $dbh->prepare("SET character set 'utf8'");
	$sth->execute;
}

# Drop tables
$sth = $dbh->prepare(<<"EOSQL");
DROP TABLE $TABLE_NAME
EOSQL
$sth->execute;


# Create tables if they don't exist
$sth = $dbh->prepare(<<"EOSQL");
CREATE TABLE IF NOT EXISTS $TABLE_NAME (
id           	int(11)		NOT NULL auto_increment,
radical_number	int(2)		NOT NULL,
radical_strokes	int(2),
radical			varchar(10)	NOT NULL,
kanji			varchar(10) NOT NULL,
kanji_strokes	int(3)		default 0,
PRIMARY KEY(id)
) TYPE=MyISAM, CHARACTER SET utf8
EOSQL
$sth->execute;

# Make sure the tables are empty
$sth = $dbh->prepare(<<"EOSQL");
TRUNCATE TABLE $TABLE_NAME
EOSQL
$sth->execute;

# Open edict file
open( $filehandle, "<:utf8", $FILE) || die("Couldn't open edict file $FILE: $!");

# Lock tables -- MyISAM
$sth = $dbh->prepare("LOCK TABLES $TABLE_NAME WRITE");
$sth->execute;

#
# Iterate through all edict lines
#
my $rad_num	= 0;
my($radical, $kanji, $strokes);
while( <$filehandle> ) {
	next if /^#/;
	
	print;
	if( /^\$ \s ([^\s]*?) \s (\d+)/x ) {
		# New radical
		$radical = $dbh->quote($1);
		$strokes = $dbh->quote($2);
		$rad_num++;
		
		next;
	}
	
	# This is a line with kanji, split it up and take them out
	chomp;
	foreach my $kanji (split '') {
		# Find stroke count
		my @kanji_ids = CDBI::Kanji->search(literal => $kanji);
		my @strokes  = CDBI::Stroke_count->search(kanji => $kanji_ids[0]->id);
		my $smallest = $strokes[0]->stroke_count;
		
		# Quote
		my $rad_num_q	= $dbh->quote($rad_num);
		$kanji			= $dbh->quote($kanji);
		
		# Insert in database
		$sth = $dbh->prepare(<<"EOSQL");
	INSERT INTO
		$TABLE_NAME
	VALUES(
		0,
		$rad_num_q,
		$strokes,
		$radical,
		$kanji,
		$smallest
	)
EOSQL

		$sth->execute;
	}
}


# Unlock table -- MyISAM
$sth = $dbh->prepare("UNLOCK TABLES");
$sth->execute;


sub usage {
	print <<EOF;
perl radk2sqlite.pl radk_file table_name
EOF
	exit;
}