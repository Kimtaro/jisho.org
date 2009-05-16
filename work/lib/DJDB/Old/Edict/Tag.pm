package DJDB::Old::Edict::Tag;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('edict_tag');
__PACKAGE__->add_columns(qw/ id edict tag /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('edict' => 'DJDB::Old::Edict');

1;