package DJDB::Old::Tanaka;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('examples');
__PACKAGE__->add_columns(qw/ eid words japanese japanese_reading english /);
__PACKAGE__->utf8_columns(qw/ words japanese japanese_reading english /);
__PACKAGE__->set_primary_key('eid');

1;