package DenshiJisho::Model::Words;

use strict;
use base 'Catalyst::Base';
use Carp;
use URI::Escape;
use Data::Dumper;
use Data::Page::Balanced;
use Encode;
use Lingua::JA::Romanize::Kana;

sub find_words_in_edict {
	my ( $self, $c ) = @_;
	
	
	# =========================================
	# = Just say no to wildcard-only searches =
	# =========================================
	if (   $c->stash->{query}->{form}->{jap} =~ m/^[*?\s]+$/
		|| $c->stash->{query}->{form}->{eng} =~ m/^[*?\s]+$/ ) {
		$c->stash->{no_search} = 1;
	}
	
	
	# ===========================
	# = Abort search if told to =
	# ===========================
	if ($c->stash->{no_search}) {
		return([], 0);
	}
	
	
	# ==========================
	# = Determine the database =
	# ==========================
	my $main_rs;
	my $dict;

	if ( $c->stash->{query}->{form}->{dict} eq 'edict' ) {
		$main_rs = $c->model('DJDB')->resultset('Old::Edict');
		$dict = 'edict';
	}
	elsif ( $c->stash->{query}->{form}->{dict} eq 'compdic' ) {
		$main_rs = $c->model('DJDB')->resultset('Old::Compdic');
		$dict = 'compdic';
	}
	elsif ( $c->stash->{query}->{form}->{dict} eq 'engscidic' ) {
		$main_rs = $c->model('DJDB')->resultset('Old::Engscidic');
		$dict = 'engscidic';
	}
	elsif ( $c->stash->{query}->{form}->{dict} eq 'enamdic' ) {
		$main_rs = $c->model('DJDB')->resultset('Old::Enamdic');
		$dict = 'enamdic';
	}
	else {
		return([], 0);
	}
	
	
	# ==================
	# = Create queries =
	# ==================
	my($query, $options);
	my $jap = $c->stash->{query}->{sql}->{jap};
	my $eng = $c->stash->{query}->{sql}->{eng};
	
	
	# ========================
	# = Specific to Japanese =
	# ========================
	if ( $c->stash->{query}->{form}->{jap} ) {
		$query->{'jap.jap'} = {'like' => $c->stash->{query}->{sql}->{jap_tokens}};
		
		my $q_jap = $c->model('DJDB')->storage->dbh->quote($jap);
		$options = {
			join => [qw/jap/],
			order_by => qq{
			    LOCATE($q_jap, kanji),
				LOCATE($q_jap, kana_reading),
				IF(kanji, CHAR_LENGTH(kanji), 0),
				CHAR_LENGTH(kana_reading),
				NOT(is_common)
			},
			group_by => [qw/me.id/],
			distinct => 1,
		}
	}
	
	
	# =======================
	# = Specific to English =
	# =======================
	if ( $c->stash->{query}->{form}->{eng} ) {
		my(@eng_like, @eng_regexp);
		foreach my $token (@{$c->stash->{query}->{sql}->{eng_tokens}}) {
			push @eng_like, $token->{for_like};
			push @eng_regexp, $token->{for_regexp};
		}
		
		$query->{'meanings'} = [
			'-and' =>
				[ '-and' => map {{'like' => $_}} @eng_like],
				[ '-and' => map {{'regexp' => $_}} @eng_regexp],
		];
		
		my $q_eng = $c->model('DJDB')->storage->dbh->quote($eng);
		$options = {
			order_by => qq{
				IF(kanji, CHAR_LENGTH(kanji), 0),
				CHAR_LENGTH(kana_reading),
				is_common,
				LOCATE($q_eng, meanings)
			},
			group_by => [qw/me.id/],
		}
	}
	
	
	# ================================================
	# = When searching for both Japanese and English =
	# ================================================
	if ( $c->stash->{query}->{form}->{jap} && $c->stash->{query}->{form}->{eng} ) {
		my $q_jap = $c->model('DJDB')->storage->dbh->quote($jap);
		my $q_eng = $c->model('DJDB')->storage->dbh->quote($eng);
		
		$options = {
			join => [qw/jap/],
			order_by => qq{
				LOCATE($q_jap, kana_reading),
				LOCATE($q_jap, kanji),
				IF(kanji, CHAR_LENGTH(kanji), 0),
				CHAR_LENGTH(kana_reading),
				is_common,
				LOCATE($q_eng, meanings)
			},
			group_by => [qw/me.id/],
		}
	}
	
	
	# ======================
	# = Common words only? =
	# ======================
	if ($c->stash->{query}->{form}->{common} && $c->stash->{query}->{form}->{common} eq 'on') {
		$query->{is_common} = 1;
	}
	
	
	# =================
	# = Do the search =
	# =================
	my @result = $main_rs->search($query, $options);
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
	
	# ====================
	# = Inflate the data =
	# ====================
	my $romaji;
	my $rid = 0;
	my $i = 0;
	my $tag_prefix	= $dict eq 'edict' ? '' : $dict . '_';
	my $flavour = $c->flavour;
	
	if ($c->stash->{query}->{form}->{romaji} && $c->stash->{query}->{form}->{romaji} eq 'on') {
		$romaji = Lingua::JA::Romanize::Kana->new();
	}
	
	foreach my $row (@result) {
	    #
		# Word object
		#
		my $word = {
			'kanji' => $row->kanji,
			'kana' => $row->kana,
			'kana_reading' => $row->kana_reading,
			'tags' => $row->tags,
			'meanings' => $row->meanings,
			'is_common' => $row->is_common,
			'tag_prefix' => $tag_prefix,
		};
		
		
		#
		# Row ID
		#
		$word->{rid} = $rid +=2;
		
		
		#
		# Convert kana to romaji
		#
		if ($c->stash->{query}->{form}->{romaji} && $c->stash->{query}->{form}->{romaji} eq 'on') {
			$word->{kana} = decode_utf8($romaji->chars(encode_utf8($word->{kana})));
		}
		
		
		#
		# Make keys for links
		#
		my $key				= $word->{"kanji"} ? $word->{"kanji"} : $word->{"kana"};
		my $key_uj			= Unicode::Japanese->new($key);
		my $key_euc			= $key_uj->euc();
		my $key_sjis		= $key_uj->sjis();
		
		$word->{"key"}		= $key;
		$word->{"key_euc"}	= uri_escape( $key_euc );
		$word->{"key_sjis"}	= uri_escape( $key_sjis );
		
		
		#
		# Swap secondary meanings tag and tags pertaining to it
		#
		$word->{"meanings"} =~ s/(\s* \[ [^]] \]) \s* (\(\d+\)) /$2 $1/gx;
		
		
		#
		# Expand global tags
		#
		$word->{'tags'} = [
			map { {
				'expanded' => $c->config->{'tags'}->{$tag_prefix . $_} || $_,
				'tag' => $_
			} } split /,/, $word->{'tags'}
		];
		
		
		#
		# Separate senses
		#
		$word->{'meanings'} =~ s|/|; |g;
		
		
		#
		# Expand meaning specific tags
		#
		$word->{'meanings'} =~ s| \[ (.*?) \] |
			$flavour eq 'j_mobile' ? 
				$c->config->{tags}->{$tag_prefix . $1}
				:
				qq/<span class="tags mn_tags" title="$1">(/ . $c->config->{tags}->{$tag_prefix . $1} . ')</span>';
		|egix;
		
		
		#
		# Special for the www flavour
		#
		if ( $c->flavour eq 'www' ) {
			#
			# Mark the search terms
			# First with non-alphanumeric so we don't match our own html later on
			# Like if we search for "span span", the second will match the first
			#

			# Match Japanese
			foreach my $token (@{$c->stash->{query}->{regexp}->{jap_tokens}}) {
				$word->{"kanji"}	=~ s{ (\Q$token\E) }{<=$1=>}gix;
				$word->{"kana"}		=~ s{ (\Q$token\E) }{<=$1=>}gix;
			}

			# Match English
			foreach my $token (@{$c->stash->{query}->{regexp}->{eng_tokens}}) {
				$word->{"meanings"} =~ s/ (?: (< [^>]*? \Q$token\E [^<]*?>) | (\Q$token\E) ) /
					if ($1) {
						$1;
					}
					else {
						"<=$2=>";
					}
				/egix;
			}
			
			# Replace intermittent match notation with spans
			$word->{"kanji"}		=~ s{<=}{<span class="match">}g;
			$word->{"kanji"}		=~ s{=>}{</span>}g;
			$word->{"kana"}			=~ s{<=}{<span class="match">}g;
			$word->{"kana"}			=~ s{=>}{</span>}g;
			$word->{"meanings"}		=~ s{<=}{<span class="match">}g;
			$word->{"meanings"}		=~ s{=>}{</span>}g;
		}
		
		
		#
		# Line break meanings
		#
		$word->{'meanings'} = [ split(m{(?:^|\s|/)\(\d\d?\)}, $word->{'meanings'}) ];
		shift  @{$word->{'meanings'}} if scalar @{$word->{'meanings'}} > 1;
		
		
		#
		# Save it
		#
		push @{$c->stash->{search}->{words}}, $word;
	}
}


1;
