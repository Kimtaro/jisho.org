package DJDB::JMdict::Sense::Field;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_sense_field');
__PACKAGE__->add_columns(qw/ id sense field /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('sense' => 'DJDB::JMdict::Sense');

1;