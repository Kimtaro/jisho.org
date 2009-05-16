package DJDB::Old::Kanjidic::Reading;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji_reading');
__PACKAGE__->add_columns(qw/ id kanji reading normalized r_type r_status on_type /);
__PACKAGE__->utf8_columns(qw/ reading normalized /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;