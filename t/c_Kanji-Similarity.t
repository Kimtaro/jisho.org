use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'DenshiJisho' }
BEGIN { use_ok 'DenshiJisho::Controller::Kanji::Similarity' }

ok( request('/kanji/similarity')->is_success, 'Request should succeed' );


