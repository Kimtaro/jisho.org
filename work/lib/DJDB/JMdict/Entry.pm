package DJDB::JMdict::Entry;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_entry');
__PACKAGE__->add_columns(qw/ id ent_seq etymology /);
__PACKAGE__->utf8_columns(qw/ etymology /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('languages' => 'DJDB::JMdict::Entry::Lang');
__PACKAGE__->has_many('dialects' => 'DJDB::JMdict::Entry::Dial');
__PACKAGE__->has_many('kanjis' => 'DJDB::JMdict::Kanji');
__PACKAGE__->has_many('readings' => 'DJDB::JMdict::Reading');
__PACKAGE__->has_many('senses' => 'DJDB::JMdict::Sense');

1;