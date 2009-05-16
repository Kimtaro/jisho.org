package DJDB::Old::Edict::Text::Jap;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('edict_text_jap');
__PACKAGE__->add_columns(qw/ id edict jap type /);
__PACKAGE__->utf8_columns(qw/ jap /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('edict' => 'DJDB::Old::Edict');

1;