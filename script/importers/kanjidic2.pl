#!/usr/bin/perl -w
#
#  kanjidic2_to_sql.pl
#
#  Converts a Kanjidic2 xml file to sql

use strict;
use warnings;
use Encode;
use utf8;
use XML::Twig;
use XML::Simple;
use Data::Dumper;
use File::Basename;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, '..', '..', 'lib')->stringify;
use DenshiJisho::Schema::DJDB;
use DenshiJisho::Lingua;
use DenshiJisho::Importer qw($djdb_schema insert);

#
# Init stuff
#
usage() unless $#ARGV >= 0;
binmode(STDOUT, 'utf8');
select STDOUT; $| = 1; # Make unbuffered

my $FILE = $ARGV[0];
my $counter = 0;

#
# Lock tables
#

print "Locking\n";
$djdb_schema->txn_begin;

#
# Delete all the previous entries
#

print "Deleting\n";
$djdb_schema->resultset('Kanji')->delete;

#
# Create an XML::Parser parser that will iterate over all the entry elements
#
my $p = new XML::Twig(
	twig_handlers => {
		character => \&handle_character,
		meaning => \&handle_meaning,
	},
);

print "Parsing\n";
$p->parsefile($FILE);

#
# Unlock tables
#

print "Committing\n";
$djdb_schema->txn_commit();

#
# Handle
#

sub handle_meaning {
	my ( $t, $s ) = @_;

  # Normalize meaning languages
  $s->set_att(m_lang => $s->{att}->{m_lang} || 'en');
}

sub handle_character {
	my ( $t, $s ) = @_;
	my ( $kana, $kana_reading, $options, $ele );

  # Make hash
  my $current = XMLin(
    $s->outer_xml,
    ForceArray => [qw/stroke_count variant freq rad_value rad_name rmgroup nanori reading meaning dic_ref q_code cp_value/]
  );
  
  # Clean up arrays
  $current->{dic_number}->{dic_ref} =
    fold_up($current->{dic_number}->{dic_ref}, 'dr_type');
    
  $current->{codepoint}->{cp_value} =
    fold_up($current->{codepoint}->{cp_value}, 'cp_type', {remove_hash => 'content'});
    
  $current->{query_code}->{q_code} =
    fold_up($current->{query_code}->{q_code}, 'qc_type');
  
  foreach my $rm_group (@{$current->{reading_meaning}->{rmgroup}}) {
    $rm_group->{reading} =
      fold_up($rm_group->{reading}, 'r_type');
    
    $rm_group->{meaning} =
      fold_up($rm_group->{meaning}, 'm_lang', {remove_hash => 'content'});
  }

  $current = make_sane($current);
  save($current);
  
	if ( $counter++ % 10  == 0 ) {
    print q{.};
    #warn Dumper $current;
  }
  elsif ( $counter % 500 == 0 ) {
    print qq{ $counter } . localtime() . qq{\n};
    #$djdb_schema->txn_commit();
    #exit;
  }
}

sub make_sane {
  my ( $old ) = @_;
  my $new = {};
  
  $new->{kanji} = $old->{literal};
  $new->{indices} = $old->{dic_number}->{dic_ref};
  $new->{jlpt_level} = $old->{misc}->{jlpt};
  $new->{frequencies} = $old->{misc}->{freq};
  $new->{variants} = $old->{misc}->{variant};
  $new->{stroke_counts} = $old->{misc}->{stroke_count};
  $new->{grade} = $old->{misc}->{grade};
  $new->{radical_names} = $old->{misc}->{rad_name};
  $new->{code_points} = $old->{codepoint}->{cp_value};
  $new->{readings_meanings} = $old->{reading_meaning};
  $new->{codes} = $old->{query_code}->{q_code};
  $new->{radicals} = $old->{radical}->{rad_value};
  
  $new->{readings_meanings}->{groups} = $new->{readings_meanings}->{rmgroup};
  delete(${$new->{readings_meanings}}{rmgroup});
  
  return $new;
}

sub save {
  my ($data) = @_;
  
  my $kanji = $djdb_schema->resultset('Kanji')->create({
	  kanji => $data->{kanji},
	  jlpt => $data->{jlpt_level},
	  grade => $data->{grade},
	  strokes => $data->{stroke_counts}->[0],
	  data => $data,
  });
  
  # Dictionary references
  foreach my $dic_ref_key ( keys %{$data->{indices}} ) {
    foreach my $ref ( @{$data->{indices}->{$dic_ref_key}} ) {
      insert_code('index', $dic_ref_key, $ref->{content}, $kanji->id);      
    }
  }
  
  # Codepoints
  foreach my $cp_key ( keys %{$data->{code_points}} ) {
    foreach my $ref ( @{$data->{code_points}->{$cp_key}} ) {
      insert_code('codepoint', $cp_key, $ref, $kanji->id);      
    }
  }
  
  # Query codes
  foreach my $q_key ( keys %{$data->{codes}} ) {
    foreach my $ref ( @{$data->{codes}->{$q_key}} ) {
      insert_code('code', $q_key, $ref->{content}, $kanji->id);      
    }
  }
  
  # Radicals
  foreach my $ref ( @{$data->{radicals}} ) {
    insert_code('radical', $ref->{rad_type}, $ref->{content}, $kanji->id);      
  }
  
  # Misc
  foreach my $ref ( @{$data->{stroke_counts}} ) {
    insert_code('misc', 'stroke_count', $ref, $kanji->id);      
  }

  foreach my $ref ( @{$data->{variants}} ) {
    insert_code('variant', $ref->{var_type}, $ref->{content}, $kanji->id);      
  }

  # Readings & meanings
  foreach my $group ( @{$data->{readings_meanings}->{groups}} ) {
    foreach my $r_key ( keys %{$group->{reading}} ) {
      foreach my $ref ( @{$group->{reading}->{$r_key}} ) {
        insert_reading($r_key, $ref->{content}, $kanji->id);
        if ( $ref->{content} =~ s/[-.]//g ) {
          insert_reading($r_key, $ref->{content}, $kanji->id);          
        }
        if ( $ref->{content} =~ /\p{InKatakana}/ ) {
          insert_reading($r_key, katakana_to_hiragana($ref->{content}), $kanji->id);          
        }
      }
    }
    
    foreach my $m_key ( keys %{$group->{meaning}} ) {
      foreach my $ref ( @{$group->{meaning}->{$m_key}} ) {
        insert_meaning($m_key, $ref, $kanji->id);
      }
    }
  }
  
  foreach my $ref ( @{$data->{readings_meanings}->{nanori}} ) {
    insert_reading('nanori', $ref, $kanji->id);
  }
    
}

sub insert_code {
  insert('INSERT INTO kanji_codes SET section = ?, type = ?, value = ?, kanji_id = ?',
    $_[0], $_[1], $_[2], $_[3]
  );      
}

sub insert_reading {
  insert('INSERT INTO kanji_readings SET type = ?, reading = ?, kanji_id = ?',
    $_[0], $_[1], $_[2]
  );      
}

sub insert_meaning {
  insert('INSERT INTO kanji_meanings SET language = ?, meaning = ?, kanji_id = ?',
    $_[0], $_[1], $_[2]
  );      
}

sub fold_up {
  my ($struct, $key, $options) = @_;
  my $new = {};
  
  foreach my $elem ( @{$struct} ) {
    my $key_val = $elem->{$key};
    delete ${$elem}{$key};

    if ( $options->{remove_hash} ) {
      $elem = $elem->{$options->{remove_hash}};
    }
    
    push @{$new->{$key_val}}, $elem;
  }
  
  return $new;
}

#
# Usage
#
sub usage {
	print <<EOF;
perl kanjidic2.pl Kanjidic2_file
EOF
	exit;
}

__END__

=head1 Kanjidic2 importer

=head2 fold_up
  
Turns

  'reading' => [
               {
                 'r_type' => 'pinyin',
                 'content' => 'wa2'
               },
               {
                 'r_type' => 'korean_r',
                 'content' => 'wae'
               },
               {
                 'r_type' => 'korean_r',
                 'content' => 'wa'
               },
               {
                 'r_type' => 'korean_h',
                 'content' => "\x{c65c}"
               },
               {
                 'r_type' => 'korean_h',
                 'content' => "\x{c640}"
               },
               {
                 'r_type' => 'ja_on',
                 'content' => "\x{30a2}"
               },
               {
                 'r_type' => 'ja_on',
                 'content' => "\x{30a2}\x{30a4}"
               },
               {
                 'r_type' => 'ja_on',
                 'content' => "\x{30ef}"
               },
               {
                 'r_type' => 'ja_kun',
                 'content' => "\x{3046}\x{3064}\x{304f}.\x{3057}\x{3044}"
               }
             ],

into

  'reading' => {
               'korean_h' => [
                             {
                               'content' => "\x{c65c}"
                             },
                             {
                               'content' => "\x{c640}"
                             }
                           ],
               'korean_r' => [
                             {
                               'content' => 'wae'
                             },
                             {
                               'content' => 'wa'
                             }
                           ],
               'ja_on' => [
                          {
                            'content' => "\x{30a2}"
                          },
                          {
                            'content' => "\x{30a2}\x{30a4}"
                          },
                          {
                            'content' => "\x{30ef}"
                          }
                        ],
               'pinyin' => [
                           {
                             'content' => 'wa2'
                           }
                         ],
               'ja_kun' => [
                           {
                             'content' => "\x{3046}\x{3064}\x{304f}.\x{3057}\x{3044}"
                           }
                         ]
             },

With the C<remove_hash => 'key'> option, turns into this:

  'reading' => {
               'korean_h' => [
                             "\x{c65c}",
                             "\x{c640}"
                           ],
               'korean_r' => [
                             'wae',
                             'wa'
                           ],
               'ja_on' => [
                          "\x{30a2}",
                          "\x{30a2}\x{30a4}",
                          "\x{30ef}"
                        ],
               'pinyin' => [
                           'wa2'
                         ],
               'ja_kun' => [
                           "\x{3046}\x{3064}\x{304f}.\x{3057}\x{3044}"
                         ]
             },

=cut
