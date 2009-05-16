package DenshiJisho::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Encode;
use HTML::Entities;
use DenshiJisho::Lingua;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

sub auto : Private {
  my ( $self, $c ) = @_;
			
	# Check limit
	if (defined $c->req->params->{nolimit} && $c->req->params->{nolimit} eq 'on') {
		$c->stash->{query}->{limit} = 0;
	}
	else {
		$c->stash->{query}->{limit} = $c->config->{result_limit};
	}
	
	$c->languages([qw(en)]);
}

sub default : Private {
	my ( $self, $c ) = @_;
    
	$c->res->status(404);
}

sub index : Private {
	my ( $self, $c ) = @_;
	
	$c->stash->{template} = 'home/index.tt';
	$c->stash->{page} = 'home';
}

#
# Favicon
#
sub favicon : Path('/favicon.ico') {
	my ( $self, $c ) = @_;
	
	$c->res->redirect($c->uri_for('/static/images/favicon.ico'));
	$c->detach;
}

#
# Apple touch icon
#
sub touch : Path('/apple-touch-icon.png') {
	my ( $self, $c ) = @_;
	
	$c->res->redirect($c->uri_for('/static/images/apple-touch-icon.png'));
	$c->detach;
}

#
# Sitemap
#
sub sitemap : Path('/sitemap.xml') {
	my ( $self, $c ) = @_;

	$c->res->redirect($c->uri_for('/static/files/sitemap.xml'));
	$c->detach;
}

#
# Robots.txt
#
sub robots : Path('/robots.txt') {
	my ( $self, $c ) = @_;

	$c->res->redirect($c->uri_for('/static/files/robots.txt'));
	$c->detach;
}

#
# Google verification file
#
sub google_verification_file : Path('/google74fb886d33a1c79f.html') {
	my ( $self, $c ) = @_;
	
	$c->res->redirect($c->uri_for('/static/files/google74fb886d33a1c79f.html'));
	$c->detach;
}

# ----------------------------
# Handle old links
# ----------------------------
sub old_about : Regex('^about\.pl') {
	my ( $self, $c ) = @_;

	$c->res->redirect("/about");
}

sub old_index : Regex('^index\.pl') {
	my ( $self, $c ) = @_;

	# Determine the page
	my $page;
	if ($c->req->param('dict') eq 'ex') {
		$page = 'sentences';
	}
	else {
		$page = 'words';
	}
	
	# Get the search params
	my $eng = $c->req->param('eng');
	my $jap = $c->req->param('jap');
	my $dict = $c->req->param('dict');
	my $common = $c->req->param('common');
	
	# Redirect
	$c->res->redirect("/$page?translation=$eng&japanese=$jap&source=$dict&common=$common");
}

# ----------------------------
# Render page
# ----------------------------
sub end : Private {
	my ( $self, $c ) = @_;
	
	$c->forward('render');
		
	# Automatically populate the form if we have a template
	if ( ($c->flavour() eq 'www' || $c->flavour() eq 'j_mobile') && defined $c->stash->{template} ) {
		$c->fillform($c->req->params);
	}
	
	# Print QueryLog to the log if requested
	if ( $c->log->is_info ) {
		my $ql = $c->model('DJDB')->querylog;
		my $total = sprintf('%0.6f', $ql->time_elapsed);
		my $qcount = $ql->count;
		
		$c->log->info('Total SQL Time: ' . $total);
		$c->log->info('Total Queries:  ' . $qcount);
		
		if ( $qcount > 0 ) {
			my $i = 0;
			my $ana = DBIx::Class::QueryLog::Analyzer->new({ querylog => $ql });
			
			foreach my $q (@{$ana->get_sorted_queries}) {
			    $c->log->info(
			        sprintf("%0.6fs, %i%%, %s", $q->time_elapsed, ($q->time_elapsed / $total) * 100, $q->sql)
			    );
			}
		}
	}
}

sub render : ActionClass('RenderView') {
	my ( $self, $c ) = @_;
	
	# Custom 404 page
	if( $c->res->status == 404 ) {
		$c->stash->{template} = '404.tt';
	}
	
	# Set the flavour if we have a template
	if ( $c->stash->{template} ) {
		$c->stash->{template} = q{flavour/} . $c->flavour() . q{/} . $c->stash->{template};
	}
}

1;
