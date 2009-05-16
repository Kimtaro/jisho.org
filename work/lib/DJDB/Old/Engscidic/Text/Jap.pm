package DJDB::Old::Engscidic::Text::Jap;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('engscidic_text_jap');
__PACKAGE__->add_columns(qw/ id engscidic jap type /);
__PACKAGE__->utf8_columns(qw/ jap /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('engscidic' => 'DJDB::Old::Engscidic');

1;