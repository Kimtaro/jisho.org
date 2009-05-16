package DJDB::JMdict::Kanji::Info;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_kanji_info');
__PACKAGE__->add_columns(qw/ id kanji ke_inf /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::JMdict::Kanji');

1;