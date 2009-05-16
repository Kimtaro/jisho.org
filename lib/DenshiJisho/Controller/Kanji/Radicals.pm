package DenshiJisho::Controller::Kanji::Radicals;

use strict;
use base 'Catalyst::Base';
use Encode;
use Data::Dumper;
use List::MoreUtils qw/uniq/;
use utf8;

=head1 NAME

DenshiJisho::Controller::Kanji::Radicals - Catalyst component

=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

Catalyst component.

=head1 METHODS

=over 4

=item default

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    
	$c->stash->{template} = 'kanji/radicals/index.tt';
	$c->stash->{page} = 'kanji_by_rad';
}

sub find : Local {
	my ( $self, $c ) = @_;
	my @radicals;
	
	# Check for radicals
	if ($c->req->param("rad")) {
		@radicals = $c->req->param("rad");
	}
	else {
		$c->stash->{json} = {reset => 1};
		$c->stash(current_view => 'JSON');
		return;
	}
	
	# Extract the radical numbers
	@radicals = map {m/_([^_]*?)$/; $1} @radicals;
	
	# Search
	my $kr_rs = $c->model('DJDB::KanjiRadicals')->search(
	  {
			'radical.number' => {'-in' => \@radicals},
		},
		{
		  join => [qw/radical/],
			order_by => ['kanji_strokes', 'IF((kanji_grade = 9), 10, (10 - kanji_grade))'],
			group_by => [qw/kanji_id/],
			having => {'count(number)' => {'>' => $#radicals}},
		}
	);
	
	my @ids = map {$_->kanji_id} $kr_rs->all;
	my $kanji_rs = $c->model('DJDB::Kanji')->search({
	  id => {'-in' => \@ids }
	}, {
	  order_by => ['FIELD(id, '. join(',', @ids) .')']
	});
	
	# Create the output
	my $output = {};
	my $count = 0;
	my $current_strokes = 0;
	my $last_strokes = 0;
	my @kanjis;
	my @bunch;
	my @kanji_ids;
	
	foreach my $kanji ( $kanji_rs->all ) {
		$count++;
		my $ord = ord($kanji->kanji);
		my $strokes = $kanji->strokes;
		my $grade = $kanji->grade;
		push @kanjis, $kanji->kanji;
		push @kanji_ids, $kanji->id;

		# Make sure strokes is a number, so it doesn't get stringified in the JSON conversion
		push( @{$output->{kanji}}, {
			ord => $ord,
			grade => "g$grade",
			strokes => $strokes+0,
		});
	}
	
	# Find valid radicals for continued searching
	my $validation = "";
	if ( scalar(@kanjis) > 0 ) {
		my $valid_rs = $c->model('DJDB::KanjiRadicals')->search_related('radical', {
			kanji_id => {'-in' => \@kanji_ids},
    }, {
      group_by => [qw/radical_id/],
    });

		my @valid_radicals;
		foreach my $radical ( $valid_rs->all ) {
			$output->{is_valid_radical}->{"rad_" . $radical->strokes . '_' . $radical->number} = 1;
		}
	}
	
	# Deploy output
	my $notice = $count == 0 ? "" : "(Jōyō kanji are colored darker)";
	$output->{count} = $count;
	$output->{notice} = $notice;
	
	$c->stash->{json} = $output;
	$c->stash(current_view => 'JSON');
}

=back


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
