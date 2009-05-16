package DenshiJisho::Model::RadicalInfo;

use strict;
use warnings;
use base 'Catalyst::Model';

sub load_radical_info {
	my( $self, $c ) = @_;
	
	# Bogus radical to offset by one since the radicals begin at 1 and not 0
	push @{$c->config->{radicals}}, {
		glyph => "X",
	};
	
	# Load radical info
	my $rads;
	open($rads, '<:utf8' , $c->path_to('radical_info.txt')) || die("Couldn't open radical info file: $!");
	
	while (<$rads>) {
		next if /^#/;
		
		if (m/^(.)$/) {
			push @{$c->config->{radicals}}, {
				glyph => $1,
			};
		}
	}
	close($rads);
	
	# Log
	$c->log->info('Loaded radical info');
}

=head1 NAME

DenshiJisho::Model::RadicalInfo - Catalyst Model

=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
