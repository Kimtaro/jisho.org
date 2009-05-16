package DJUserDB::UserRole;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('user_roles');
__PACKAGE__->add_columns(qw/ user_id role_id /);
__PACKAGE__->set_primary_key(qw/ user_id role_id /);

__PACKAGE__->belongs_to(user => 'DJUserDB::User', 'user_id');
__PACKAGE__->belongs_to(role => 'DJUserDB::Role', 'role_id');

1;