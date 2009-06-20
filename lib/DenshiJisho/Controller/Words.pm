package DenshiJisho::Controller::Words;

use strict;
use base 'Catalyst::Base';
use Unicode::Japanese;
use utf8;
use URI::Escape;
use Encode;
use DenshiJisho::Lingua;
use Data::Dumper;
use Carp;

sub auto : Private {
  my ( $self, $c ) = @_;
	
  # Support legacy param names
  $c->req->params->{japanese} = $c->req->param('jap') if $c->req->param('jap');
  $c->req->params->{translation} = $c->req->param('eng') if $c->req->param('eng');
  $c->req->params->{source} = $c->req->param('dict') if $c->req->param('dict');

	# Save state
	$c->persistent_form('words', [qw(common romaji translation_language)]);
  
  # Convenience conversions
	$c->req->params->{japanese} = romaji_to_kana(fullwidth_to_halfwidth($c->req->param('japanese')));
	$c->req->params->{translation} = fullwidth_to_halfwidth($c->req->param('translation'));

	# Set the display language to the same as the search language
	$c->req->params->{translation_language} = q(eng) unless $c->req->param('translation_language');
	$c->stash->{display_language} = $c->req->param('display_language') || $c->req->param('translation_language');

	# Check limit
	$c->stash->{limit} = $c->req->param('nolimit') eq 'on' ? 0 : $c->config->{result_limit};
		
	# Check dictionary
	$c->req->params->{source} = q(jmdict) unless $c->config->{sources}->{words}->{names}->{ $c->req->param('source') };
}

sub index : Private {
	my ( $self, $c ) = @_;
	
	$c->stash->{page} = 'words';
	$c->stash->{template} = 'words/index.tt';
	
	return unless $c->req->param('translation') || $c->req->param('japanese');
	$c->stash->{is_search} = 1;

	my ($words, $pager, $dictionary_counts) = $c->model('DJDB::Words')->find_words_with_dictionary_counts({
	  source => $c->req->param('source'),
	  japanese => $c->req->param('japanese'),
	  gloss => $c->req->param('translation'),
	  language => $c->req->param('translation_language'),
	  common_only => $c->req->param('common') eq 'on' ? 1 : 0,
	  page => $c->req->param('page') || 1,
	  limit => $c->stash->{limit},
	});

  $c->stash->{source_counts} = $dictionary_counts;
  $c->stash->{pager} = $pager;

	# Check with MeCab if it's an inflected word
	my $lemmatized = lemmatize_japanese($c->stash->{form}->{j});
	$c->stash->{suggest}->{deinflected} = ($lemmatized && $lemmatized eq $c->req->param('japanese')) ? q() : $lemmatized;
	
	# If no words found, suggest other searches
	my $total = $dictionary_counts->{$c->req->param('source')};
	if ($total == 0) {
		my $key				  = $c->req->param('japanese');
		my $key_uj			= Unicode::Japanese->new($key);
		my $key_euc			= $key_uj->euc;
		my $key_sjis		= $key_uj->sjis;
			
		$c->stash->{suggest}->{key} = $key;
		$c->stash->{suggest}->{key_euc} = uri_escape( $key_euc );
		$c->stash->{suggest}->{key_sjis} = uri_escape( $key_sjis );
		
		if ($key =~ m/\p{Han}/) {
			$c->stash->{suggest}->{key_has_kanji} = 1;
		}
	}

  # Add Smart.fm dictionary tab
  if ( $c->req->param('source') eq 'smartfm' ) {
    $words = $c->model('Smartfm')->items($c->req->param('japanese') . ' ' . $c->req->param('translation'), {
      language => $c->req->param('translation_language'),
    });
    $total = scalar @{$words->{all}};
    $c->stash->{source_counts}->{smartfm} = $total;
  }
  else {
    $c->stash->{source_counts}->{smartfm} = '<span id="smartfm_count">...</span>';    
  }
  
	# Display the words
  if ( $c->flavour eq q{iphone} ) {
    $c->stash->{json} = {
      words => $words,
      total => $total,
      pager => {
        last_page => $c->stash->{pager}->last_page,
        current_page => $c->stash->{pager}->current_page,
      }
    };
    $c->stash(current_view => 'JSON');
  }
	else {
		$c->stash->{result}->{words} = $words;
		$c->stash->{result}->{total} = $total;
	
		if ($c->stash->{is_lite}) {
			$c->stash->{template} = 'lite/words/result.tt';
		}
		else {
			$c->stash->{template} = 'words/result.tt';
		}
  }
}

1;
