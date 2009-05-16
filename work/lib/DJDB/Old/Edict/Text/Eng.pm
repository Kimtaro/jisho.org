package DJDB::Old::Edict::Text::Eng;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('edict_text_eng');
__PACKAGE__->add_columns(qw/ id edict eng /);
__PACKAGE__->utf8_columns(qw/ eng /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('edict' => 'DJDB::Old::Edict');

1;