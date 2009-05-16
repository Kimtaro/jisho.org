package DJUserDB::User;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('users');
__PACKAGE__->add_columns(qw/ id username password email register_time login_time /);
__PACKAGE__->utf8_columns(qw/ username /);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(map_user_role => 'DJUserDB::UserRole', 'user_id');

1;