package DJDB::Old::Enamdic::Text::Jap;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('enamdic_text_jap');
__PACKAGE__->add_columns(qw/ id enamdic jap type /);
__PACKAGE__->utf8_columns(qw/ jap /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('enamdic' => 'DJDB::Old::Enamdic');

1;