package DenshiJisho::Model::Text;

use strict;
use warnings;
use base qw/Catalyst::Model Class::Accessor::Fast/;

use Text::MeCab;
use Encode;
use Data::Dumper;
use utf8;

our $VERSION = '0.1';

__PACKAGE__->mk_accessors(qw/mecab chasen/);

sub new {
	my $class = shift;
	
	# Class::Accessor provides new()
	my $self = $class->NEXT::new(@_);
	
    $self->mecab( Text::MeCab->new() );
	
	return $self;
}

=head1 NAME

DenshiJisho::Model::Text - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub parse_text {	
	my ($self, $text, $c) = @_;
		
	return unless defined $text;
	
	my $mecab = $self->mecab();
	
	my @result;
	my $skip_next = 0;
	for (my $node = $mecab->parse($text); $node; $node = $node->next) {
		my ($hinshi, $saibun1, $saibun2, $saibun3, $katuyoukei, $katuyougata, $genkei, $yomi, $hatuon) = split(',', decode_utf8 $node->feature);
		my $surface = decode_utf8 $node->surface;
		my $dict;
		
		# Ignore BOS/EOS and punctuation
		next if $hinshi eq "BOS/EOS"
		     || $hinshi eq "記号";
		
		# Check if this node belongs to the previous
		# TODO: What if we have three or more connected nodes?
		#		Then the third will be inserted in the empty second one
		if (
				($hinshi eq '助動詞' && $katuyoukei eq '特殊・ナイ') # -nai form
			||	($hinshi eq '動詞' && $katuyougata eq '連用形') # -te form
			) {
			$result[$#result]->{surface} .= $surface;
			next;
		}
        
        # Do secondary hiragana lookup with Chasen here somewhere
        
		# Look up the base form if it includes kanji
		# TODO: Also do a lookup on the constructed surface form
		if ( $genkei =~ m/\p{Han}/ ) {
			$dict =
				$c->model('DJDB')->resultset("Old::Edict")->search({kanji => $genkei})->first ||
				$c->model('DJDB')->resultset("Old::Enamdic")->search({kanji => $genkei})->first ||
				$c->model('DJDB')->resultset("Old::Engscidic")->search({kanji => $genkei})->first ||
				$c->model('DJDB')->resultset("Old::Compdic")->search({kanji => $genkei})->first;
		}
		
		# Save it
		push @result, {
			surface => $surface,
			genkei => $genkei,
			dict => $dict,
		};
	}
	
	return \@result;
}

1;
