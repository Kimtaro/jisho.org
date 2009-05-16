package DJDB::JMdict::Kanji;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_kanji');
__PACKAGE__->add_columns(qw/ id entry keb /);
__PACKAGE__->utf8_columns(qw/ keb /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('infos' => 'DJDB::JMdict::Kanji::Info');
__PACKAGE__->has_many('prios' => 'DJDB::JMdict::Kanji::Prio');
__PACKAGE__->has_many('kanji_readings' => 'DJDB::JMdict::KanjiReading');
__PACKAGE__->many_to_many('readings' => 'kanji_readings', 'reading');
__PACKAGE__->belongs_to('entry' => 'DJDB::JMdict::Entry');

1;