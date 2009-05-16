package DJDB::JMdict::KanjiReading;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_kanji_reading');
__PACKAGE__->add_columns(qw/ kanji reading /);
__PACKAGE__->set_primary_key(qw/ kanji reading /);
__PACKAGE__->belongs_to('kanji' => 'DJDB::JMdict::Kanji');
__PACKAGE__->belongs_to('reading' => 'DJDB::JMdict::Reading');

1;