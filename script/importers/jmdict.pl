#!/usr/bin/perl -w
#
#  jmdict.pl
#
#  Imports JMdict and JMnedict files

use strict;
use warnings;
use Encode;
use utf8;
use XML::Parser;
use Data::Dumper;
use List::MoreUtils qw(any first_value uniq);
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
my $TYPE = $FILE;
$TYPE = (fileparse($TYPE))[0];
$TYPE =~ m|^([a-zA-Z0-9]+)|;
$TYPE = lc $1;
my $counter = 0;
my $statistics = 0;
my %is_common_tag = (
  news1 => 1,
  ichi1 => 1,
  spec1 => 1,
  gai1 => 1,
  common => 1,
);

#
# Lock tables
#

print "Locking\n";
$djdb_schema->txn_begin;

#
# Delete all the previous JMdict entries
#

print "Deleting\n";
my $words = $djdb_schema->resultset('Words');
$words->search({source => $TYPE})->delete;

#
# Create an XML::Parser that will iterate over all the entry elements
#
my $p = new XML::Parser(
	Handlers => {
		Start => \&handle_start,
		End => \&handle_end,
		Char => \&handle_char,
		Default => \&handle_default,
	},
	NoExpand => 1,
);

print "Parsing\n";
$p->parsefile($FILE);

#
# Unlock tables
#

print "Comitting\n";
$djdb_schema->txn_commit;

#
# Global var for the parsing
#
my $current;

sub handle_start {
	my ( $expat, $element, %attrs ) = @_;
	
	# Create the hashrefs that will store each entry
	if ($element eq 'entry') {
	  $current = {};
	}
	elsif ($element eq 'r_ele') {
	  $current->{re_nokanji} = 0;
	  $current->{re_restrs} = [];
	}
	elsif ($element eq 'sense' || $element eq 'trans') {
	  $current->{sense} = {};
	}
	elsif ($element eq 'keb') {
	  $current->{representation} = {};
	}
	
	# Clear the current string
	$current->{string} = '';
	
	# Save the element attributes
	$current->{attributes} = \%attrs;
}

sub handle_end {
	my ( $expat, $element ) = @_;
	my ( $options );
	
	#print "  " x @{$expat->{Context}} . $element . "\n";
	
	if ( $element eq 'entry' ) {
	  compile_reading_groups($current);
	  save($current);
	  
  	if ( $counter++ % 10  == 0 ) {
      print q{.};
    }
    elsif ( $counter % 500 == 0 ) {
      print qq{ $counter } . localtime() . qq{\n};
    }
  }
	elsif ( $element eq 'ent_seq' ) {
		$current->{entry}->{source_id} = $current->{string};
	}
	elsif ( $element eq 'reb' ) {
		$current->{reading} = {
		  reading => $current->{string},
		  is_common => 0,
		};
	}
	elsif ( $element eq 're_nokanji' ) {
		$current->{reading}->{re_nokanji} = 1;
	}
	elsif ( $element eq 're_restr' ) {
		push @{$current->{reading}->{re_restrs}}, $current->{string};
	}
	elsif ( $element eq 're_inf' || $element eq 're_pri' || $element eq 'ke_inf' || $element eq 'ke_pri' ) {
	  my $tag = {
      tag => $current->{string},
      type => $element,
    };
        
    if ( $element eq 're_inf' || $element eq 're_pri' ) {
      push @{$current->{reading}->{tags}}, $tag;
      if ( $is_common_tag{$current->{string}} ) {
        $current->{reading}->{is_common} = 1;
        $current->{has_common} = 1;
      }
    }
    else {
      push @{$current->{representation}->{tags}}, $tag;
      if ( $is_common_tag{$current->{string}} ) {
        $current->{representation}->{is_common} = 1;
        $current->{has_common} = 1;
      }
    }
	}
	elsif ( $element eq 'r_ele' ) {
	  if ( $current->{re_restrs} && scalar @{$current->{re_restrs}} > 0 ) {
  	  foreach my $re_restr (@{$current->{reading}->{re_restrs}}) {
        push @{$current->{readings}}, {
          re_restr => $re_restr,
          reading => $current->{reading}->{reading},
          is_common => $current->{reading}->{is_common},
          tags => $current->{reading}->{tags},
        };
  	  }
	  }
	  else {
      push @{$current->{readings}}, $current->{reading};
	  }
	}
	elsif ( $element eq 'keb' ) {
		$current->{representation}->{representation} = $current->{string};
	}
	elsif ( $element eq 'k_ele' ) {
	  push(@{$current->{representations}}, $current->{representation});
	}
	elsif ( $element eq 'field' || $element eq 'misc' || $element eq 'dial' || $element eq 'pos' || $element eq 'name_type' ) {
		my $tag = {
      tag => $current->{string},
      type => $element,
    };
        
    push @{$current->{sense}->{tags}}, $tag;
	}
	elsif ( $element eq 'stagk' || $element eq 'stagr' ) {
		push @{$current->{sense}->{restrs}}, {
      type => $element,
      value => $current->{string},
    };
	}
	elsif ( $element eq 'ant' || $element eq 'xref' ) {
		push @{$current->{sense}->{crossrefs}}, {
		  type => $element,
      value => $current->{string},
    };
	}
	elsif ( $element eq 'gloss' || $element eq 'trans_det' ) {
		push @{$current->{sense}->{glosses}}, {
      type => $current->{attributes}->{'xml:lang'} || 'eng',
      value => $current->{string},
    };
	}
	elsif ( $element eq 's_inf' ) {
		push @{$current->{sense}->{details}}, {
      value => $current->{string},
    };
	}
	elsif ( $element eq 'lsource' ) {
		push @{$current->{sense}->{origins}}, {
		  type => $current->{attributes}->{'xml:lang'},
      value => $current->{string},
    };
	}
	elsif ( $element eq 'sense' || $element eq 'trans' ) {
	  push @{$current->{senses}}, $current->{sense};
	}
}

sub handle_char {
	my ( $expat, $string ) = @_;
	
	# Trim whitespace from beginning and end	
	$string =~ s/( ^[\s\n]+ | [\s\n]+$ )//gx;
	$current->{string} .= $string;
}

sub handle_default {
	my ( $expat, $string ) = @_;
	
	# This together with NoExpand will keep the entities from being expanded
	if ($string =~ s/^& ([^;]+) ;$/$1/gx) {
		$current->{string} .= $string;
	}
}

sub save {
  my ( $current ) = @_;
  
  my $data = {
    source => $TYPE,
    source_id => $current->{entry}->{source_id},
    reading_groups => $current->{reading_groups},
    senses => $current->{senses},
  };
  
  my $word = $words->create({
	  source => $TYPE,
	  source_id => $current->{entry}->{source_id},
	  has_common => $current->{has_common},
	  data => $data,
  });
  
  # Grab the readings and representations and make sure there are no duplicates
  my @readings = ();
  my @representations = ();
  foreach my $group (@{$current->{reading_groups}}) {
    foreach my $reading (@{$group->{readings}}) {
      push @readings, $reading->{reading};
    }
    foreach my $representation (@{$group->{representations}}) {
      push @representations, $representation->{representation};
      
      # While we're in here, let's take the tags
      foreach my $tag ( @{$representation->{tags}} ) {
        insert('INSERT INTO word_tags SET `group` = ?, type = ?, value = ?, word_id = ?',
          'representation',
          $tag->{type},
          $tag->{tag},
          $word->id
        );
      }
    }
  }
  @readings = uniq @readings;
  @representations = uniq @representations;
  
  foreach my $reading (@readings) {
    insert('INSERT INTO representations SET representation = ?, word_id = ?',
      $reading,
      $word->id
    );
    
    if ($reading =~ /\p{InKatakana}/) {
      $reading = katakana_to_hiragana($reading);
      next if any { $_ eq $reading } @readings;
      insert('INSERT INTO representations SET representation = ?, word_id = ?',
        $reading,
        $word->id
      );
    }
  }
    
  foreach my $representation (@representations) {
    insert('INSERT INTO representations SET representation = ?, word_id = ?',
      $representation,
      $word->id
    );
    
    if ($representation =~ /\p{InKatakana}/) {
      $representation = katakana_to_hiragana($representation);
      next if any { $_ eq $representation } @representations;
      insert('INSERT INTO representations SET representation = ?, word_id = ?',
        $representation,
        $word->id
      );
    }
  }
    
  foreach my $sense (@{$current->{senses}}) {
    foreach my $gloss (@{$sense->{glosses}}) {
      insert('INSERT INTO meanings SET language = ?, meaning = ?, word_id = ?',
        $gloss->{type},
        $gloss->{value},
        $word->id
      );
    }
    
    foreach my $tag ( @{$sense->{tags}} ) {
      insert('INSERT INTO word_tags SET `group` = ?, type = ?, value = ?, word_id = ?',
        'sense',
        $tag->{type},
        $tag->{tag},
        $word->id
      );
    }
  }
}

sub compile_reading_groups {
  my ($current) = @_;
  
  my $readings = $current->{readings};
  my $representations = $current->{representations};
  my $groups = {};
  $current->{reading_groups} = [];
    
  # Create reading groups based on the kanji they are restricted to
  foreach my $reading (@{$readings}) {
    my $key = $reading->{re_nokanji} ? 'nokanji'
                                     : $reading->{re_restrs} ? join(';', @{$reading->{re_restrs}})
                                                             : 'none';
    $groups->{$key} ||= {};
    my $group = $groups->{$key};
    $group->{readings} ||= [];
    push @{$group->{readings}}, $reading;
  }
    
  # Add the representations to the appropriate reading groups
  foreach my $representation (@{$representations}) {
    my @keys;
    foreach my $g_key (keys %{$groups}) {
      push(@keys, $g_key) if any { $_ eq $representation->{representation} } split(';', $g_key);
    }
    @keys = ('none') unless scalar @keys > 0;
    foreach my $key (@keys) {
      my $group = $groups->{$key};
      $group->{representations} ||= [];
      push @{$group->{representations}}, $representation
        unless ${$group->{readings}}[0]->{re_nokanji};
    }
  }
    
  # Create the proper reading group array, ordered by the readings
  foreach my $reading (@{$readings}) {
    foreach my $key (keys %{$groups}) {
      my $group = $groups->{$key};
      if ( any { $_->{reading} eq $reading->{reading} } @{$group->{readings}} ) {
        push @{$current->{reading_groups}}, $group;
        last;
      }
    }
  }  
}

#
# Usage
#
sub usage {
	print <<EOF;
perl jmdict.pl JMdict_file
EOF
	exit;
}
