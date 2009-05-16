#!/usr/bin/perl -w
#
#  kanjidic2mysql.pl
#
#  Converts a Kanjidic2 xml file to a set of sql tables

#
# Database stuff
#
package Jisho::DBI;
use base 'Class::DBI::mysql';
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

package Kanji::Codepoint;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_codepoint');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Radical;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_radical');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::StrokeCount;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_stroke_count');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Variant;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_variant');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Freq;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_freq');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::RadName;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_rad_name');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::DicNumber;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_dic_number');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::QueryCode;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_query_code');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Meaning;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_meaning');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Reading;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_reading');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji::Nanori;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji_nanori');
__PACKAGE__->has_a( kanji => "Kanji" );

package Kanji;
use base 'Jisho::DBI';
__PACKAGE__->set_up_table('kanji');
__PACKAGE__->has_many( codepoints			=> "Kanji::Codepoint");
__PACKAGE__->has_many( radicals				=> "Kanji::Radical");
__PACKAGE__->has_many( strokes				=> "Kanji::StrokeCount");
__PACKAGE__->has_many( variants				=> "Kanji::Variant");
__PACKAGE__->has_many( frequencies			=> "Kanji::Freq");
__PACKAGE__->has_many( radical_names		=> "Kanji::RadName");
__PACKAGE__->has_many( dictionary_numbers	=> "Kanji::DicNumber");
__PACKAGE__->has_many( query_codes			=> "Kanji::QueryCode");
__PACKAGE__->has_many( meanings				=> "Kanji::Meaning");
__PACKAGE__->has_many( readings				=> "Kanji::Reading");
__PACKAGE__->has_many( nanoris				=> "Kanji::Nanori");

#
# Main
#

package Main;

use strict;
use warnings;
use Encode;
use utf8;
use XML::Twig;
use XML::Simple;
use Data::Dumper;

#
# Init stuff
#
usage() unless $#ARGV >= 0;
binmode(STDOUT, 'utf8');

my $FILE		= $ARGV[0];
my $counter		= 0;
my $character;
my %dr_sort_order = (
	busy_people      => 8,
	crowley          => 17,
	gakken           => 4,
	halpern_kkld     => 12,
	halpern_njecd    => 14,
	heisig           => 16,
	henshall         => 3,
	henshall3        => 2,
	kanji_in_context => 11,
	kodansha_compact => 13,
	moro             => 6,
	nelson_c         => 5,
	nelson_n         => 15,
	oneill_kk        => 7,
	oneill_names     => 9,
	sakade           => 1,
	sh_kk            => 10,
	tutt_cards       => 18,
);

#
# Create an XML::Twig parser that will iterate over all the character elements
#
my $t = XML::Twig->new(
	twig_roots => {
		character => \&handle_character,
	}
);

$t->parsefile($FILE);
$t->flush;

sub handle_character {
	my ( $lt, $elt ) = @_;
	
	my $char = XMLin('<character>'. encode_utf8($elt->xml_string) .'</character>', ForceArray => [qw/cp_value rad_value stroke_count variant freq rad_name dic_ref q_code reading meaning nanori/]);
	
	# TODO: Check for importing empty literal kanji
	#print $char->{literal};
	
	my $kanji = Kanji->create({
		literal	=> $char->{literal},
		grade	=> $char->{misc}->{grade},
	});

	# Codepoints
	foreach my $item (@{$char->{codepoint}->{cp_value}}) {
		$kanji->add_to_codepoints({
			kanji	=> $kanji->id,
			cp_type		=> $item->{cp_type},
			cp_value	=> $item->{content},
		});
	}
	
	# Radicals
	foreach my $item (@{$char->{radical}->{rad_value}}) {
		$kanji->add_to_radicals({
			kanji	=> $kanji->id,
			rad_type	=> $item->{rad_type},
			rad_value	=> $item->{content},
		});
	}
	
	# Stroke count
	foreach my $item (@{$char->{misc}->{stroke_count}}) {
		$kanji->add_to_strokes({
			kanji		=> $kanji->id,
			stroke_count	=> $item,
		});
	}
	
	# Variants
	foreach my $item (@{$char->{misc}->{variant}}) {
		$kanji->add_to_variants({
			kanji	=> $kanji->id,
			var_type	=> $item->{var_type},
			variant		=> $item->{content},
		});
	}
	
	# Frequency
	foreach my $item (@{$char->{misc}->{freq}}) {
		$kanji->add_to_frequencies({
			kanji	=> $kanji->id,
			frequency	=> $item,
		});
	}
	
	# Radical name
	foreach my $item (@{$char->{misc}->{rad_name}}) {
		$kanji->add_to_radical_names({
			kanji	=> $kanji->id,
			rad_name	=> $item,
		});
	}
	
	# Dictionary references
	foreach my $item (@{$char->{dic_number}->{dic_ref}}) {
		$kanji->add_to_dictionary_numbers({
			kanji	=> $kanji->id,
			dr_type			=> $item->{dr_type},
			dic_ref			=> $item->{content},
			dj_sort_order	=> $dr_sort_order{ $item->{dr_type} },
			m_vol			=> $item->{m_vol},
			m_page			=> $item->{m_page},
		});
	}
	
	# Query codes
	foreach my $item (@{$char->{query_code}->{q_code}}) {
		$kanji->add_to_query_codes({
			kanji	=> $kanji->id,
			qc_type		=> $item->{qc_type},
			q_code		=> $item->{content},
		});
	}
	
	# Readings
	foreach my $item (@{$char->{reading_meaning}->{rmgroup}->{reading}}) {
		# Normalize reading into only hiragana
		my $normalized = $item->{content};
		
		if ($item->{r_type} eq 'ja_on' || $item->{r_type} eq 'ja_kun') {
			if ($normalized =~ /\p{InKatakana}/) {
				$normalized = katakana_to_hiragana($normalized);
			}
			
			$normalized =~ s/[-.]//g;
		}
		
		$kanji->add_to_readings({
			kanji	=> $kanji->id,
			r_type		=> $item->{r_type},
			normalized	=> $normalized,
			reading		=> $item->{content},
		});
	}
	
	# Meanings
	foreach my $item (@{$char->{reading_meaning}->{rmgroup}->{meaning}}) {
		if (ref($item) eq 'HASH') {
			next unless $item->{content};
			
			$kanji->add_to_meanings({
				kanji	=> $kanji->id,
				m_lang		=> $item->{m_lang},
				meaning		=> $item->{content},
			});
		}
		else {
			# English meanings lack the m_lang property
			$kanji->add_to_meanings({
				kanji	=> $kanji->id,
				m_lang		=> 'en',
				meaning		=> $item,
			});
		}
	}
	
	# Nanoris
	foreach my $item (@{$char->{reading_meaning}->{nanori}}) {
		$kanji->add_to_nanoris({
			kanji	=> $kanji->id,
			nanori		=> $item,
		});
	}
	
	$kanji->update;
	
	# Make sure memory is a-groovin'
	$lt->purge;
	
	print "$counter\n" if $counter++ % 100 == 0;
}

#
# Usage
#
sub usage {
	print <<EOF;
perl kanjidic2mysql.pl kanjidic_file
EOF
	exit;
}

#
# Katakana to hiragana
#
sub katakana_to_hiragana {
	my ( $kata ) 	 = @_;
	my $iterations	 = 0;
	my $hira         = '';

	while( length($kata) ) {
		# Exit if we seem to be stuck in an infinite loop
		# We should really raise an error here

		last if $iterations++ == 50;

		my $char	= substr($kata, 0, 1, "");
		my $ord		= ord $char;

		if( $ord >= 12449 and $ord <= 12534 ) {
			$hira .= chr($ord - 96);
		}
		else {
			$hira .= $char;
		}
	}
	
	return $hira;
}
