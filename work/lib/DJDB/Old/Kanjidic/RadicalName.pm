package DJDB::Old::Kanjidic::RadicalName;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji_rad_name');
__PACKAGE__->add_columns(qw/ id kanji rad_name /);
__PACKAGE__->utf8_columns(qw/ rad_name /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;