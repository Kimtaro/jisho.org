package DJDB::JMdict::Sense;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('jmdict_sense');
__PACKAGE__->add_columns(qw/ id entry /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('miscs' => 'DJDB::JMdict::Sense::Misc');
__PACKAGE__->has_many('parts_of_speech' => 'DJDB::JMdict::Sense::Pos');
__PACKAGE__->has_many('fields' => 'DJDB::JMdict::Sense::Field');
__PACKAGE__->has_many('xrefs' => 'DJDB::JMdict::Sense::Xref');
__PACKAGE__->has_many('antonyms' => 'DJDB::JMdict::Sense::Ant');
__PACKAGE__->has_many('stagrs' => 'DJDB::JMdict::Sense::Stagr');
__PACKAGE__->has_many('stagks' => 'DJDB::JMdict::Sense::Stagk');
__PACKAGE__->has_many('glosses' => 'DJDB::JMdict::Sense::Gloss');
__PACKAGE__->belongs_to('entry' => 'DJDB::JMdict::Entry');

1;