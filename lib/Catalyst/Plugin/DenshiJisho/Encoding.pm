package Catalyst::Plugin::DenshiJisho::Encoding;

use strict;
use Encode;

our $VERSION = '0.1';

sub finalize {
    my $c = shift;
	my $charset;
	my $meta_charset;

    unless ( $c->response->body ) {
        return $c->NEXT::finalize;
    }

    unless ( $c->response->content_type =~ m|^text/html| ) {
        return $c->NEXT::finalize;
    }

	if ( $c->flavour eq 'j_mobile' ) {
		$meta_charset = $charset = 'shift_jis';
	}
	else {
	    $charset = 'utf8';
		$meta_charset = 'utf-8';
	}
	
	my $content_type = $c->response->content_type;
    $content_type =~ s/\;\s*$//;
    $content_type =~ s/\;*\s*charset\s*\=.*$//i;
    $content_type .= sprintf("; charset=%s", $meta_charset );
    $c->response->content_type($content_type);
	
	$c->response->body( encode($charset, $c->response->body) );

    $c->NEXT::finalize;
}

sub prepare_parameters {
    my $c = shift;
	my $charset;
	
	$c->NEXT::prepare_parameters(@_);
	
	if ( $c->flavour eq 'j_mobile' ) {
		$charset = 'shift_jis';
	}
	else {
	    $charset = 'utf8';
	}

    for my $value ( values %{ $c->request->{parameters} } ) {

        if ( ref $value && ref $value ne 'ARRAY' ) {
            next;
        }

        $_ = decode($charset, $_) for ( ref($value) ? @{$value} : $value );
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::DenshiJisho::Encoding

=head1 SYNOPSIS

    use Catalyst qw[DenshiJisho::Encoding];


=head1 DESCRIPTION

Based on L<Catalyst::Plugin::Unicode> and L<Catalyst::Plugin::Charsets::Japanese>. Does UTF-8 on everything except Japanese cell phones. Also properly sets the charset in the content-type header.

=head1 OVERLOADED METHODS

=over 4

=item finalize

Encodes body into UTF-8 or Shift-JIS octets.

=item prepare_parameters

Decodes parameters into a sequence of logical characters.

=back

=head1 SEE ALSO

L<Encode>, L<Catalyst>.

=head1 AUTHOR

Kim Ahlström, C<kim.ahlstrom@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
