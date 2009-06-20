package DenshiJisho::View::TT;

use strict;
use base 'Catalyst::View::TT';
use Template::Stash::XS;
use Encode;
use utf8;
use Lingua::EN::Numbers qw(num2en);
use Unicode::Japanese;
use URI::Escape;
use DenshiJisho::Lingua;
use Lingua::JA::Romanize::Kana;
use Data::Dumper;
use Carp;

sub new {
	my $self = shift;
	
	$self->config({
		TAG_STYLE => "php",
		PRE_CHOMP => 1,
		POST_CHOMP => 1,
		TRIM => 1,
		ANYCASE => 1,
		EVAL_PERL => 1,
		COMPILE_EXT => ".tct",
		COMPILE_DIR => q(/tmp/denshijisho_) . DenshiJisho->VERSION . q(_on_) . DenshiJisho->engine,
		STASH => Template::Stash::XS->new,
		FILTERS => {
			decode_utf8 => \&decode_utf8_filter,
			'ord' => \&ord_filter,
			num2en => \&number_to_english,
			hilight_matches => [\&hilight_matches, 1],
			romaji => [\&romaji, 1],
		},
	});
	
	$Template::Stash::SCALAR_OPS->{ encodings_for } = \&encodings_for;
	$Template::Stash::HASH_OPS->{ glosses_for_language } = \&glosses_for_language;
	
	# Turn on timing if we are debugging
	if ( DenshiJisho->debug ) {
		$self->config->{TIMER} = 1;
	}
	
	return $self->next::method(@_);
}

sub decode_utf8_filter {
	my $text = shift;
	
	return decode_utf8($text);
}

sub ord_filter {
	my $text = shift;
	
	return ord($text);
}

sub number_to_english {
	my $text = shift;
	
	return num2en($text);
}

sub hilight_matches {
  my ( $context, @args ) = @_;
  
  return sub {
    my $text = shift;
    my $tokens = shift @args || ();
  	
    foreach my $token (@{$tokens}) {
        $text =~ s{ ($token) }{<span class="match">$1</span>}gix;
    }
    
    return $text;
  }
}

sub romaji {
  my ( $context, @args ) = @_;
  my $romaji = Lingua::JA::Romanize::Kana->new();
  
  return sub {
    my $kana = shift;
    my $run = shift @args;
    
    $kana = decode_utf8($romaji->chars(encode_utf8($kana))) if $run;
    
    return $kana;
  }
}

sub encodings_for {
  my $key         = shift;
  my $key_uj			= Unicode::Japanese->new($key);
  my $key_euc			= uri_escape( $key_uj->euc );
  my $key_sjis		= uri_escape( $key_uj->sjis );

  return([$key_euc, $key_sjis]);
}

sub glosses_for_language {
  my ( $sense, $lang ) = @_;
  return( [ grep { $_->{type} eq $lang } @{$sense->{glosses}} ] );
}

1;
