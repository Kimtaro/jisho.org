package DenshiJisho::Controller::Lite;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

DenshiJisho::Controller::Lite - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub lite_setup : PathPart('lite') Chained('/') Args(1) {
    my ( $self, $c, $path ) = @_;

    $c->stash->{is_lite} = 1;
	
	if ($path eq 'words') {
		$c->forward("/words/index");
	}
	else {
		$c->res->status(404);
	}
}

=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
