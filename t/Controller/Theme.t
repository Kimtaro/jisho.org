
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DenshiJisho' );
use_ok('DenshiJisho::Controller::Theme');

ok( request('theme')->is_success );

