package DJDB::Old::Compdic::Text::Eng;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('compdic_text_eng');
__PACKAGE__->add_columns(qw/ id compdic eng /);
__PACKAGE__->utf8_columns(qw/ eng /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('compdic' => 'DJDB::Old::Compdic');

1;