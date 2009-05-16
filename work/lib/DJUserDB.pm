package DJUserDB;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/
	User
	Role
	UserRole
/);

1;