package DJDB::JMdict::Gloss;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_gloss');
__PACKAGE__->add_columns(qw/ id entry sense gloss g_lang g_gend /);
__PACKAGE__->utf8_columns(qw/ gloss /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('entry' => 'DJDB::JMdict::Entry');
__PACKAGE__->belongs_to('sense' => 'DJDB::JMdict::Sense');

1;