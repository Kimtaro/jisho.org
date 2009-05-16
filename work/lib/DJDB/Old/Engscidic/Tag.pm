package DJDB::Old::Engscidic::Tag;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('engscidic_tag');
__PACKAGE__->add_columns(qw/ id engscidic tag /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('engscidic' => 'DJDB::Old::Engscidic');

1;