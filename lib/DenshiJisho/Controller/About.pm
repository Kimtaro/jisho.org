package DenshiJisho::Controller::About;

use strict;
use base 'Catalyst::Controller';

=head1 NAME

DenshiJisho::Controller::About - Catalyst component

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
    
    $c->stash->{template} = 'about.tt';
    $c->stash->{page} = 'about';
}

sub donations_thanks : Path('donations/thanks') {
	my ( $self, $c ) = @_;
	
	$c->stash->{template} = 'donations_thanks.tt';
    $c->stash->{page} = 'about';
}

=back


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
