package DenshiJisho::Controller::Commandline;

use strict;
use base 'Catalyst::Controller';

sub jap : Regex('^\s*/?\s*jap(?:anese)?\s+(.*)$') {
    my ( $self, $c ) = @_;

	$c->res->redirect( $c->req->base . "words?dict=edict&jap=" . ${$c->req->snippets}[0] );
}

sub eng : Regex('^\s*/?\s*eng(?:lish)?\s+(.*)$') {
    my ( $self, $c ) = @_;

	$c->res->redirect( $c->req->base . "words?dict=edict&eng=" . ${$c->req->snippets}[0] );
}

1;
