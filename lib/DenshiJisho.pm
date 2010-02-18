package DenshiJisho;

use strict;
use Cwd;
use Catalyst qw/
	StackTrace
	ConfigLoader
	FillInForm
	I18N
	
	Session 
  Session::State::Cookie
  Session::Store::File
	
	Static::Simple
	DenshiJisho::Static
	DenshiJisho::Encoding	
	DenshiJisho::Flavour
/;
use Carp qw/croak carp/;
use Data::Dumper;

BEGIN {
	use lib __PACKAGE__->path_to('work', 'lib')->stringify;
}

our $VERSION = '3';

__PACKAGE__->setup();

# Load tags
__PACKAGE__->model('Tags')->load_tags( __PACKAGE__ );
__PACKAGE__->model('RadicalInfo')->load_radical_info( __PACKAGE__ );

sub ce {
  my $c = shift;
  my @context = caller;
  my $first = q(-) x 10 . q( ) . $context[0] . ', line ' . $context[2] . q( ) . q(-) x 50;
  my $output = qq(\n+$first\n| ) . $context[1] . qq(\n|\n);
  
  foreach my $arg (@_) {
    my $dump = Dumper $arg;
    foreach my $line (split(qq(\n), $dump)) {
      $output .= qq(| $line\n);
    }
    $output .= qq(|\n);
  }
  
  $output .= q(+) . q(-) x length($first) . qq(\n\n);
  carp $output;
}

sub persistent_form {
  my( $c, $name, $controls) = @_;
  
  if ( keys %{$c->req->params} ) {
    foreach my $control (@{$controls}) {
    	$c->session->{persistent_form}->{$name}->{$control} = $c->req->params->{$control};
    }
	}
	else {
	  $c->req->params( Catalyst::Utils::merge_hashes($c->req->params, $c->session->{persistent_form}->{$name}) );
	}
}

1;
