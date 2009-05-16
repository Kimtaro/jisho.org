package DenshiJisho::Controller::Kanji::Similarity;

use strict;
use warnings;
use base 'Catalyst::Controller';
use utf8;
use Data::Dumper;
use Encode;

=head1 NAME

DenshiJisho::Controller::Kanji::Similarity - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub default : Private {
    my ( $self, $c, @args ) = @_;

    $c->stash->{template} = 'kanji/similarity/index.tt';
	$c->stash->{page} = 'kanji_by_similarity';
	
	
	#
	# Get selection and base kanji
	#
	my @selected = splice @args, 2;
	my @base = qw/ 行 走 送 回 使 国 語 夏 一 広 病 気 般 /;
	
	# Create choices
	my $i = 0;
	my %choices = map {
		$_ => {
			kanji		=> $_,
			id			=> 'sim_' . $i++,
			selected	=> 0,
		}
	} @base;
	
	# Mark selected kanji
	foreach my $selected (@selected) {
		$selected = decode_utf8($selected);
		$choices{$selected}->{selected} = 1;
	}
	
	
	#
	# Search if we have selected kanji
	#
	if ( scalar @selected > 0 ) {
		my $radicals_rs = $c->model('DJDB')->resultset('Radk')->search(
			{
				kanji => \@selected,
			},
			{
				group_by => 'radical',
			}
		);
	
		my @radicals = map { $_->radical } $radicals_rs->all();
	
		my $kanji_rs = $c->model('DJDB')->resultset('Radk')->search(
			{
				radical => \@radicals,
			},
			{
				group_by => 'kanji',
				order_by => [qw/kanji_strokes kanji_grade_sort/],
				having => {'count(kanji)' => {'>' => $#selected}},
			}
		);
	
		@{$c->stash->{result}->{kanji}} = $kanji_rs->all();
		$c->stash->{result}->{count} = scalar @{$c->stash->{result}->{kanji}};
	}
	
	
	#
	# Output
	#
	$c->stash->{choices} = \%choices;
}


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
