use Test::More tests => 2;
use_ok( Catalyst::Test, 'DenshiJisho' );

ok( request('/')->is_success );
