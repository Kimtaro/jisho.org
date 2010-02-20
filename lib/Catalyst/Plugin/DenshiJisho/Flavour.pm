package Catalyst::Plugin::DenshiJisho::Flavour;

use Moose::Role;
use HTTP::MobileAgent;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors('flavour');

after 'prepare_parameters' => sub {
  my $c = shift;

  # Get flavour from URL param
  if ( $c->req->param('flavour') ) {
      $c->flavour( $c->req->param('flavour') );
      return;
  }
    
  # Detect the flavour by other means
  my $mobile_agent = HTTP::MobileAgent->new($c->req->user_agent);
	
	if (    !$mobile_agent->is_non_mobile 
		||   $c->req->header('host') =~ m{ ^k\. }ix
		) {
		$c->flavour('j_mobile');
	}
    elsif (  $c->req->header('host') =~ m{ ^iphone\. }ix
        ||   $c->req->user_agent =~ m{ Mobile/\S+\s+ Safari/ }ix
        ||   $c->req->user_agent =~ m{ iPhone \s+ OS }x
        ) {
        $c->flavour('iphone');
    }
	elsif ( $c->req->header('host') =~ m{ ^www\. }ix ) {
		$c->flavour('www');
	}
	else {
		$c->flavour('www');
	}
};

1;
