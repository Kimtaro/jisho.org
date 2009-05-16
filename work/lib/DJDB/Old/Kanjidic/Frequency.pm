package DJDB::Old::Kanjidic::Frequency;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('kanji_freq');
__PACKAGE__->add_columns(qw/ id kanji frequency /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;