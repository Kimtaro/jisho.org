package DenshiJisho::Controller::Sentences;

use strict;
use base 'Catalyst::Controller';
use Unicode::Japanese;
use URI::Escape;
use Data::Dumper;
use Encode;
use DenshiJisho::Lingua;

sub auto : Private {
  my ( $self, $c ) = @_;
	
  # Support legacy param names
  $c->req->params->{japanese} = $c->req->param('jap') if $c->req->param('jap');
  $c->req->params->{translation} = $c->req->param('eng') if $c->req->param('eng');
  $c->req->params->{source} = $c->req->param('dict') if $c->req->param('dict');
	
	# Convenience conversions
	$c->req->params->{japanese} = romaji_to_kana(fullwidth_to_halfwidth($c->req->param('japanese')));
	$c->req->params->{english} = fullwidth_to_halfwidth($c->req->param('english'));
	
	# Check dictionary
	$c->req->params->{source} = q(tanaka) unless $c->config->{sources}->{sentences}->{names}->{ $c->req->param('source') };
}

sub index : Private {
    my ( $self, $c ) = @_;
    
	$c->stash->{page}       = 'sentences';
	$c->stash->{template}   = 'sentences/index.tt';
	
	if ($c->req->param('eng') || $c->req->param('jap')) {
				
		# If no sentences found, suggest other searches
		if ($c->stash->{result}->{total} == 0) {
			my $key				= $c->stash->{query}->{form}->{jap};
			my $key_uj			= Unicode::Japanese->new($key);
			my $key_euc			= $key_uj->euc();
			my $key_sjis		= $key_uj->sjis();
				
			$c->stash->{suggest}->{key}			= $key;
			$c->stash->{suggest}->{key_euc}		= uri_escape( $key_euc );
			$c->stash->{suggest}->{key_sjis}	= uri_escape( $key_sjis );
			
			if ($key =~ m/\p{Han}/) {
				$c->stash->{suggest}->{key_has_kanji} = 1;
			}
		}
	
		#
		# Display the sentences
		#
		if ( $c->flavour() eq q{iphone} ) {
		    $c->stash->{json} = {
		        sentences => $c->stash->{result}->{sentences},
		        total => $c->stash->{search}->{total},
		        pager => {
		            last_page => $c->stash->{pager}->last_page(),
		            current_page => $c->stash->{pager}->current_page(),
		        }
		    };
        	$c->stash(current_view => 'JSON');
		}
		else {
		    $c->stash->{result}->{total}        = $c->stash->{search}->{total};
		    $c->stash->{template}               = 'sentences/result.tt';
	    }
	}
}

sub find : Private {
    my ( $self, $c ) = @_;
	
	# =========================================
	# = Just say no to wildcard-only searches =
	# =========================================
	if (   $c->stash->{query}->{form}->{jap} =~ m/^[*?\s]+$/
		|| $c->stash->{query}->{form}->{eng} =~ m/^[*?\s]+$/ ) {
		$c->stash->{search}->{sentences}	= [];
		$c->stash->{search}->{total}		= 0;
		return;
	}
	
	#
	# Return if no search terms given
	#
	if ($c->stash->{query}->{sql}->{jap} eq '' && $c->stash->{query}->{sql}->{eng} eq '') {
		$c->stash->{search}->{sentences}	= [];
		$c->stash->{search}->{total}		= 0;
		return;
	}

	#
	# The search terms
	#
	my @where;
	my $temp_where;
	my $temp_where2;
	my @jap;
	my @eng;
	
	if ($c->stash->{query}->{sql}->{jap}) {
		foreach my $token (@{$c->stash->{query}->{sql}->{jap_tokens}}) {
			push @jap, {'-like', $token};
		}
		
		$temp_where->{japanese}				= [ -and => @jap];
		$temp_where2->{japanese_reading}	= [ -and => @jap];
	}
	
	if ($c->stash->{query}->{sql}->{eng}) {
		foreach my $token_container (@{$c->stash->{query}->{sql}->{eng_tokens}}) {
			my $token_for_like		= $token_container->{for_like};
			my $token_for_regexp	= $token_container->{for_regexp};
			
			# Always search with LIKE. This seberely limits the number of rows that the REGEXP has to look through
			# and thus improves performancy heavily
			push @eng, {'-like', $token_for_like};
			
			# Search with regexp if we are searching for just the word and no substrings of
			# larger words. The number must be 2 since the empty string is quoted by MySQL to ''
			if( length $token_container->{for_regexp} > 2 ) {
				push @eng, {'-regexp', $token_for_regexp};
			}
		}
		
		$temp_where->{english}	= [-and => @eng];
		$temp_where2->{english}	= [-and => @eng];
	}
	
	@where = (
		{ -and => [%$temp_where] },
		{ -and => [%$temp_where2]}
	);
	
	#
	# Attributes
	#
	my %attrs = (
		order_by		=> "CHAR_LENGTH(japanese)",
	);
	
	#
	# Search
	#
	my @result = $c->model('DJDB')->resultset('Old::Tanaka')->search(\@where, \%attrs);
	$c->stash->{search}->{total} = scalar @result;
	
	# ===========
	# = Page it =
	# ===========
	my $page = $c->req->param('page') ? $c->req->param('page') : 1;
	my $pager = Data::Page::Balanced->new({
		current_page => $page,
		total_entries => scalar @result,
		entries_per_page => $c->stash->{query}->{limit} ? $c->stash->{query}->{limit} : $c->config->{'result_limit'},
	});
	$c->stash->{pager} = $pager;
    
	@result = splice(@result, ($pager->current_page() - 1) * $pager->entries_per_page(), $pager->entries_on_this_page());
	
	#
	# Give it back
	#
	$c->stash->{search}->{sentences} = \@result;
}

sub fix_up : Private {
    my ( $self, $c ) = @_;

	my $sid = 1;
	my $i = 0;
	my $flavour = $c->flavour;
	
	foreach my $row (@{$c->stash->{search}->{sentences}}) {
		#
		# Sentence object
		#
		my $sentence = {
			'english' => $row->english,
			'japanese' => $row->japanese,
			'japanese_reading' => $row->japanese_reading,
			'words' => $row->words,
			'eid' => $row->eid,
		};
		
		my $english		= $sentence->{english};
		my $japanese	= $sentence->{japanese};
		my $key			= $japanese;
		
		#
		# Tag, if any
		#
		my $tag		= "";
		my @tags;
		$english	= $sentence->{english};
		if( $english =~ s/\[M\]$// ) {
			push @tags, "Male speech";
		}
		
		if( $english =~ s/\[F\]$// ) {
			push @tags, "Female speech";
		}
		
		if( $english =~ s/\[Proverb\]$// ) {
			push @tags, "Proverb";
		}
		
		$tag .= join ", ", @tags;
		
		#
		# Special for the www and iphone flavour
		#
		if ( $flavour eq 'www' || $flavour eq 'iphone' ) {
			#
			# Link words that are in edict (the words column in the examples db)
			#
			my %used_words	= (); # So we don't link the same word several times
		
			foreach my $word ( split(/\s/, $sentence->{words}) ) {
				my( $reading, $inflected );
			
				# Remove readings, senses and inflected
				if ($word =~ s/ \( (.*) \) //x) {
					$reading = $1;
				}
			
				if ($word =~ s/ { (.*) } //x) {
					$inflected = $1;
				}
			
				$word =~ s/ \[\d+\] //x;
			
				$inflected ||= $word;
			
				# Skip if we've already done this word
				next if $used_words{$word};
			
			    if ( $flavour eq 'www' ) {
    				$japanese =~ s/ (?: (< [^>]*? $inflected [^<]*?>) | ($inflected) ) /
    					if ($1) {
    						$1;
    					}
    					else {
    						"<a href=\"\/words?jap=$word;dict=edict\">$inflected<\/a>";
    					}
    				/egix;
			    }
			    else {
			        $japanese =~ s/ (?: (< [^>]*? $inflected [^<]*?>) | ($inflected) ) /
    					if ($1) {
    						$1;
    					}
    					else {
    						"<a href=\"#words\" onClick=\"iPhone.doRelatedSearch('words', '$inflected')\">$inflected<\/a>";
    					}
    				/egix;
			    }
			
				# Mark word as used
				$used_words{$word} = 1;
			}
		
			#
			# Mark the search terms
			#
			foreach my $token ( @{$c->stash->{query}->{regexp}->{jap_tokens}} ) {
				$japanese = $c->controller('Utilities')->mark_search_terms($japanese, $token);
			}
		
			foreach my $token ( @{$c->stash->{query}->{regexp}->{eng_tokens}} ) {
				$english = $c->controller('Utilities')->mark_search_terms($english, $token);
			}
		}
		
		#
		# Add the sentence pair
		#
		push @{$c->stash->{result}->{sentences}}, {
			japanese	=> $japanese,
			english		=> $english,
			sid			=> $sid++,
			tag			=> $tag,
			key			=> $key,
			eid			=> $sentence->{eid},
		};
	}
}

1;
