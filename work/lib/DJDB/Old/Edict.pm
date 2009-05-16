package DJDB::Old::Edict;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('edict');
__PACKAGE__->add_columns(qw/ id kanji kana kana_reading tags meanings is_common /);
__PACKAGE__->utf8_columns(qw/ kanji kana kana_reading meanings /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('external_tag' => 'DJDB::Old::Edict::Tag', 'edict');
__PACKAGE__->has_many('jap' => 'DJDB::Old::Edict::Text::Jap', 'edict');
__PACKAGE__->has_many('eng' => 'DJDB::Old::Edict::Text::Eng', 'edict');

1;