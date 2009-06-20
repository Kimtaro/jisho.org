package DenshiJisho::Model::Tags;

use strict;
use base qw/Catalyst::Model/;

sub load_tags {
	my( $self, $c ) = @_;
	
	# Load tags
	my $tags;
	open($tags, '<:utf8' , $c->path_to("tags.txt")) || die("Couldn't open tags file: $!");
	while (<$tags>) {
		next if /^#/;
		
		if (m/^(\w.*?:?):\s+(.*)$/) {
			$c->config->{tags}->{$1} = $2;
		}
	}
	close($tags);
	
	# Log
	$c->log->info('Loaded tags');
}

=head1 NAME

DenshiJisho::Model::Tags - Catalyst component

=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

Catalyst component.

=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
