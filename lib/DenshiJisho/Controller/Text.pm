package DenshiJisho::Controller::Text;

use strict;
use base 'Catalyst::Base';

sub index : Private {
    my ( $self, $c ) = @_;
    
    $c->stash->{template}   = 'text/index.tt';
	$c->stash->{page}       = 'text';
	
	$c->stash->{query}->{form}->{text} = $c->req->param('text');
	
	#
	# We got parameters, so we are searching for something
	#
	if ($c->req->param('text')) {
		$c->stash->{parsed_text} = $c->model('Text')->parse_text($c->req->param('text'), $c);
		$c->stash->{template} = 'text/result.tt';
	}
}

sub url : Local {
	my ( $self, $c ) = @_;
	
	
}

1;
