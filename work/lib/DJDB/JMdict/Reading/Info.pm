package DJDB::JMdict::Reading::Info;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_reading_info');
__PACKAGE__->add_columns(qw/ id reading re_inf /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('reading' => 'DJDB::JMdict::Reading');

1;