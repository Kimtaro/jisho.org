
use Test::More tests => 3;
use_ok( Catalyst::Test, 'DenshiJisho' );
use_ok('DenshiJisho::Controller::Kanji::Radicals');

ok( request('kanji/radicals')->is_success );

