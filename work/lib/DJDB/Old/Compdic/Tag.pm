package DJDB::Old::Compdic::Tag;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('compdic_tag');
__PACKAGE__->add_columns(qw/ id compdic tag /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('compdic' => 'DJDB::Old::Compdic');

1;