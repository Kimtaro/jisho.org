package DenshiJisho::Controller::Utilities;

use strict;
use base 'Catalyst::Controller';
use Encode;
use Data::Dumper;
use utf8;

=head1 NAME

DenshiJisho::Controller::Utilities - Catalyst component

=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

Catalyst component.

=head1 METHODS

=over 4

=item romaji_to_kana

=cut

sub mark_search_terms : Private {
	my( $self, $text, $token ) = @_;
	
	#
	# Mark the search terms
	# First with non-alphanumeric so we don't match our own html later on
	# Like if we search for "span span", the second will match the first
	#
	$text =~ s/ (?: (< [^>]*? $token [^<]*?>) | ($token) ) /
		if ($1) {
			$1;
		}
		else {
			"<=$2=>";
		}
	/egix;

	# Replace intermittent match notation with spans
	$text	=~ s{<=}{<span class="match">}g;
	$text	=~ s{=>}{</span>}g;
	
	return $text;
}

sub email {
	my ($c, $options) = @_;

	my $mail = sprintf(<<EOM, 
From: Jisho.org <kim.ahlstrom\@gmail.com>
To: $options->{to}
CC: $options->{cc}
Content-Type: text/plain; charset=UTF-8; format=flowed
X-DJ-Process: $$
Subject: $options->{subject}

$options->{body}
EOM
);

	my $sendmail;
	open($sendmail, '|-', 'sendmail -i ' . $options->{to});
	print $sendmail $mail;
	close($sendmail);
}

=back


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
