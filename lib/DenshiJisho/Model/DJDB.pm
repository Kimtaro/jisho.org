package DenshiJisho::Model::DJDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';
use Data::Dumper;

sub new {
    my $self = shift->next::method(@_);

    $self->{connect_info} = {
      on_connect_do => [
        'SET NAMES utf8',
        'SET character set utf8',
      ]
    };
#    $self->schema->connection(@{$self->{connect_info}});

    return $self;
}

=head1 NAME

DenshiJisho::Model::DJDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<DJDB>

=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
