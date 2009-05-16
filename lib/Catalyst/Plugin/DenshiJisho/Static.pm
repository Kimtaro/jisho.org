package Catalyst::Plugin::DenshiJisho::Static;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Static::Simple/;

our $VERSION = '0.1';

sub prepare_action {
	my $c = shift;
	my $path = $c->req->path;
	
	$c->SUPER::prepare_action(@_);
	
	if ( $path =~ m{^/?(.*\.)v[0-9.]+\.(css|js|gif|png|jpg)$}i ) {
		$c->res->redirect("/$1$2");
	}
}

1;

=head1 NAME

Catalyst::Plugin::DenshiJisho::Static

=head1 SYNOPSIS

    use Catalyst qw[DenshiJisho::Static];


=head1 DESCRIPTION

Subclasses L<Catalyst::Plugin::Static::Simple> to redirect versioned static URL's as in the http://www.thinkvitamin.com/features/webapps/serving-javascript-fast article, this is to complement the mod_rewrite magic done in Apache, so the dev server can serve the versioned files as well.

=head1 SEE ALSO

L<Catalyst::Plugin::Static::Simple>, L<Catalyst>.

=head1 AUTHOR

Kim Ahlström, C<kim.ahlstrom@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut