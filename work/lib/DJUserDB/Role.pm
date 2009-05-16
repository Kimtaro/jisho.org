package DJUserDB::Role;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('roles');
__PACKAGE__->add_columns(qw/ id role /);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(map_user_role => 'DJUserDB::UserRole', 'role_id');

1;