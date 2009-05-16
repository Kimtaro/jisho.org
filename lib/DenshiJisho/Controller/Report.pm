package DenshiJisho::Controller::Report;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DenshiJisho::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub example : Local {
    my ( $self, $c, $example_id, $action ) = @_;

	$c->stash->{page} = 'sentences';
	
	# Make sure the example_id is numeric
	if ($example_id !~ /^\d+$/) {
		$c->stash->{template} = 'report/invalid_example.tt';
		return;
	}

    if ($action eq 'submit') {
		my $eid		= $c->req->param('eid');
		my $org_jap = $c->req->param('org_jap');
		my $jap		= $c->req->param('jap');
		my $org_eng	= $c->req->param('org_eng');
		my $eng		= $c->req->param('eng');
		my $comment	= $c->req->param('comment');
		my $name	= $c->req->param('name');
		my $email	= $c->req->param('email');
		
		$org_jap =~ s/[\n\r]//g;
		$jap =~ s/[\n\r]//g;
		$org_eng =~ s/[\n\r]//g;
		$eng =~ s/[\n\r]//g;
		$comment =~ s/\r//g;
	
		# Check so there actually was a change, this might also hinder spam-robots
		if ($org_jap eq $jap && $org_eng eq $eng) {
			$c->stash->{template} = 'report/example_no_change.tt';
			return;
		}
	
		# Send the edited example
		$c->controller('Utilities')->email({
			to => 'kim.ahlstrom@gmail.com',
			cc => 'Jim Breen <jwb@mail.csse.monash.edu.au>, Francis Bond <bond@ieee.org>',
			subject => '[Jisho.org] Example Correction',
			body  => <<EOM,
Database id: $eid

Original Japanese: $org_jap
Corrected Japanese: $jap

Original English: $org_eng
Corrected English: $eng

Name: $name
E-mail $email
Comment: $comment

EOM
		});
		
		$c->stash->{template} = 'report/example_thanks.tt';
	}
	else {
		# Display the example for editing
		$c->stash->{the_example} = $c->model('DJDB')->resultset('Old::Tanaka')->find( $example_id );
		
		if ($c->stash->{the_example}) {
			$c->stash->{template} = 'report/example.tt';
		}
		else {
			$c->stash->{template} = 'report/no_such_example.tt';
		}
	}
}


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
