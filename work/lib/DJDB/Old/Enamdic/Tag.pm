package DJDB::Old::Enamdic::Tag;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('enamdic_tag');
__PACKAGE__->add_columns(qw/ id enamdic tag /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('enamdic' => 'DJDB::Old::Enamdic');

1;