
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DenshiJisho' );
use_ok('DenshiJisho::Controller::Search::Words');

ok( request('search/words')->is_success );

