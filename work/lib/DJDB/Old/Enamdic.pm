package DJDB::Old::Enamdic;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('enamdic');
__PACKAGE__->add_columns(qw/ id kanji kana kana_reading tags meanings is_common /);
__PACKAGE__->utf8_columns(qw/ kanji kana kana_reading meanings /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('external_tag' => 'DJDB::Old::Enamdic::Tag', 'enamdic');
__PACKAGE__->has_many('jap' => 'DJDB::Old::Enamdic::Text::Jap', 'enamdic');
__PACKAGE__->has_many('eng' => 'DJDB::Old::Enamdic::Text::Eng', 'enamdic');

1;