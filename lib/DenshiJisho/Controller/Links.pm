package DenshiJisho::Controller::Links;

use strict;
use base 'Catalyst::Controller';

=head1 NAME

DenshiJisho::Controller::Links - Catalyst component

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

    $c->stash->{template} = 'links.tt';
    $c->stash->{page} = 'links';
}

=back


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
