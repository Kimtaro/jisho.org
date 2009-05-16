use strict;
use warnings;
use DateTime;
use utf8;
use File::Basename;
use FindBin qw($Bin);
use Path::Class;
use lib dir($Bin, '..', '..', 'lib')->stringify;
use DenshiJisho::Lingua;
use DenshiJisho::Importer qw($djdb_schema insert);
use Data::Dumper;

binmode(STDOUT, 'utf8');
select STDOUT; $| = 1; # Make unbuffered

my @valid_tags = qw(
  adj adv adj-na adj-no adj-pn adj-s adj-t adj-f aux aux-v conj int n n-adv n-t n-suf v1 v5 v5u v5k v5g v5s v5t v5n v5h v5b v5p v5m v5r v5k-s v5z v5aru v5uru vi vs vs-s vk vt abbr arch col exp fam fem gikun gram hon hum id iK ik io MA male m-sl neg neg-v obs osc oK ok pol prt pref qv sl suf uK uk vulg X p s u g f m h obsc onom vz vs-i v5u-s v5r-i ateji Buddh chn comp derog ek male-sl match rare mg fg ng a-no vul pr ling
  
  kyb: osb: ksb: ktb: tsb: thb: ar: zh: de: en: fr: el: iw: ja: ko: kr: nl: no: pl: ru: sv: bo: eo: es: in: it: lt: pt: hi: ur: mn: kl: ai: sanskr: sa: he: la: tsug: kyu: id: ms: th: :vi
);
my %valid_tags;

usage() if $#ARGV < 0;

my $file = $ARGV[0];
my $LANG = $ARGV[1] || 'eng';
my $TYPE = $file;
$TYPE = (fileparse($TYPE))[0];
$TYPE =~ m|^([a-zA-Z0-9]+)|;
$TYPE = $1;

parse($file, $TYPE);

sub parse {
  my ($file, $TYPE) = @_;
  
  my $filehandle;
  my $encoding = $TYPE eq 'cedict' ? 'encoding(utf8)' : 'encoding(euc-jp)';
  open( $filehandle, "<:$encoding", $file) || die("Couldn't open file $file: $!");
  
  printf("%s - Deleting\n", DateTime->now);
  $djdb_schema->txn_begin;
  $djdb_schema->resultset('Words')->search({source => $TYPE})->delete;

  # Numbers works as tags in engscidic
  if( $TYPE eq 'engscidic' ) {
  	push @valid_tags, qw(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20);
  }

  # This also works as the tag index lookup
  %valid_tags = map {$_, $_} @valid_tags;

  printf("%s - Parsing\n", DateTime->now);
  my $line = 1;
  my $saw_id = 0;
  while ( <$filehandle> ) {
    chomp;

    unless ( $TYPE eq 'engscidic' || $TYPE eq '4jword3' || $TYPE eq 'cedict' ) {
  		# Skip lines before the version identifier line
  		if (/^？？？？/) {
  			$saw_id = 1;
  			next;
  		}
  		next unless $saw_id;
	  }
		
		next if $TYPE eq 'classical' && /^ ％/x; # This is a comment in "classical"
		next if $TYPE eq 'cedict' && /^\#/x; # This is a comment in "cedict"
  	
    parse_line($_);
    
  	if ( $line++ % 10  == 0 ) {
      print q{.};
    }
    elsif ( $line % 500 == 0 ) {
      print qq{ $line } . localtime() . qq{\n};
    }
  }
  
  printf("%s - Committing\n", DateTime->now);
  $djdb_schema->txn_commit;

  close($filehandle);

  printf("%s - Parsed %d lines\n", DateTime->now, $line);
}

sub parse_line {
  my ($line)  = @_;
  my $entry   = {
    source => $TYPE,
    source_id => 0,
  };
	my ($representation, $reading, $tags, $meanings, $is_common) = ("" x 5);
    
	if ( m{^
	      ([^[/]*) \s? # Representation
	      (?: \[ ([^]]*) \] \s )? # Reading
	      (.+) # Meanings
	      $}x
	) {
	  if ( $-[2] ) {
  		$reading        = $2;
  		$representation = $1;
  		$representation =~ s/\s*$//;
	  }
	  else {
  	  $reading = $1;
	  }
		$entry->{senses_part}      = $3;
	}
	else {
		die("Error in file format on line $.: $_");
	}

	# Check if word is common and delete (P) marker
	if ( $entry->{senses_part} =~ s{ / \( P \)/ $ }{}x ) {
		$is_common = 1;
	}
	else {
		$is_common = 0;
	}
	$entry->{is_common} = $is_common;
	
	# Build readings
  $entry->{readings} = [{
    reading => $reading,
    is_common => $is_common,
  }];
  if ( $representation ) {
    ${$entry->{readings}}[0]->{representations} = [{
      representation => $representation,
      is_common => $is_common,
      tags => [],
    }];
  }
	
	# Get all senses/glosses
	$entry->{senses} = parse_senses($entry->{senses_part});
	delete $entry->{senses_part};
	
	#printf Dumper $entry;
	
	save_entry($entry);
}

sub save_entry {
  my ( $entry ) = @_;
  
  my $word = $djdb_schema->resultset('Words')->create({
  	source => $TYPE,
  	data => $entry,
  	has_common => $entry->{is_common},
  });
  
  if ( $TYPE eq 'classical' ) {
    my $reading = @{$entry->{readings}}[0]->{reading};
    my $representation = ${${$entry->{readings}}[0]->{representations}}[0]->{representation};
    $entry->{readings} = [];
	  foreach my $r (split q{／}, $reading) {
	    $r =~ s/^ー//;
  	  push @{$entry->{readings}}, {
  	    reading => $r,
  	  }
	  }
	  if ( $representation ) {
	    my $n = $#{$entry->{readings}} > 1 ? 2 : 0;
	    ${$entry->{readings}}[$n]->{representations} = [{
	      representation => $representation,
	    }];
	  }
	}
  
  foreach my $reading (@{$entry->{readings}}) {  	
    insert('INSERT INTO representations SET representation = ?, word_id = ?',
      $reading->{reading},
      $word->id
    );
  
    if ( $reading->{reading} =~ /\p{InKatakana}/ ) {
      insert('INSERT INTO representations SET representation = ?, word_id = ?',
        katakana_to_hiragana($reading->{reading}),
        $word->id
      );
    }
    
    foreach my $representation (@{$reading->{representations}}) {
      insert('INSERT INTO representations SET representation = ?, word_id = ?',
        $representation->{representation},
        $word->id
      );
  
      if ($representation->{representation} =~ /\p{InKatakana}/) {
        insert('INSERT INTO representations SET representation = ?, word_id = ?',
          katakana_to_hiragana($representation->{representation}),
          $word->id
        );
      }
      
      foreach my $tag ( @{$representation->{tags}} ) {
        insert('INSERT INTO word_tags SET type = ?, value = ?, word_id = ?',
          $tag->{type},
          $tag->{tag},
          $word->id
        );
      }
    }
  }
  
  my @senses;
  foreach my $sense ( @{$entry->{senses}} ) {        
    foreach my $gloss ( @{$sense->{glosses}} ) {
      insert('INSERT INTO meanings SET language = ?, meaning = ?, word_id = ?',
        'eng',
        $gloss,
        $word->id
      );
    }
    
    foreach my $tag ( @{$sense->{tags}} ) {
      insert('INSERT INTO word_tags SET type = ?, value = ?, word_id = ?',
        $tag->{type},
        $tag->{tag},
        $word->id
      );
    }
  }
}

sub parse_senses {
  my ( $senses_string ) = @_;
  my $i = 0;
  my @senses;
  
	while ( $senses_string =~ s{ / ([^/]+?) (?= / | $ ) }{}x ) {
	  my $gloss = $1;
	  next if $gloss =~ /^ \s+ $/x;
    
	  # Glosses are indicated by (1)..(n), or nothing if only one distinct gloss
	  if ( $gloss =~ s/ \( (\d+) \) \s+ //x ) {
	    $i++ if $1 == $i + 2;
	  }
	  
	  my @tags_and_glosses = parse_gloss($gloss);
	  foreach my $tag (@{$tags_and_glosses[0]}) {
  	  push @{$senses[$i]->{tags}}, {
  	    type => $TYPE,
  	    tag => $tag,
  	  };	    
	  }
    push @{$senses[$i]->{glosses}}, {
      value => $tags_and_glosses[1],
      type => 'eng',
    };
	}
	
	return \@senses;
}

sub parse_gloss {
  my ( $gloss ) = @_;
  my @tags;
  
  while( $gloss =~ / (?<!\w) ( \( [^)]+? \) | \s+ \( \d+ \)$ ) /gx ) {
    next unless $1;
		my $original = $1;
		my $gloss_tags = substr $original, 1, -1;

		foreach my $tag ( split ",", $gloss_tags ) {
			$tag =~ s/\s//g;
			if( $valid_tags{$tag} or $tag =~ m/:$/ ) {
        push @tags, $tag;
        $gloss =~ s/ \Q$original\E \s* //x;
			}
		}
	}

	return (\@tags, $gloss);
}

sub usage {
	print <<EOF;
perl edict.pl edict_formatted_file
EOF
	exit;
}