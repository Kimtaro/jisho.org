package DJDB::JMdict::Entry::Dial;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_entry_dial');
__PACKAGE__->add_columns(qw/ id entry dial /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('entry' => 'DJDB::JMdict::Entry');

1;