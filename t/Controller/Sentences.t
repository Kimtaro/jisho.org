
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DenshiJisho' );
use_ok('DenshiJisho::Controller::Sentences');

ok( request('sentences')->is_success );

