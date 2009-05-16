package DJDB::Old::Engscidic;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('engscidic');
__PACKAGE__->add_columns(qw/ id kanji kana kana_reading tags meanings is_common /);
__PACKAGE__->utf8_columns(qw/ kanji kana kana_reading meanings /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('external_tag' => 'DJDB::Old::Engscidic::Tag', 'engscidic');
__PACKAGE__->has_many('jap' => 'DJDB::Old::Engscidic::Text::Jap', 'engscidic');
__PACKAGE__->has_many('eng' => 'DJDB::Old::Engscidic::Text::Eng', 'engscidic');

1;