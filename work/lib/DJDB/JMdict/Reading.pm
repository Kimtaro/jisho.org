package DJDB::JMdict::Reading;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_reading');
__PACKAGE__->add_columns(qw/ id entry reb reb_normalized re_nokanji /);
__PACKAGE__->utf8_columns(qw/ reb reb_normalized /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('infos' => 'DJDB::JMdict::Reading::Info');
__PACKAGE__->has_many('prios' => 'DJDB::JMdict::Reading::Prio');
__PACKAGE__->has_many('kanji_readings' => 'DJDB::JMdict::KanjiReading');
__PACKAGE__->many_to_many('kanjis' => 'kanji_readings', 'kanji');
__PACKAGE__->belongs_to('entry' => 'DJDB::JMdict::Entry');

1;