package DJDB::Old::Kanjidic::QueryCode;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('kanji_query_code');
__PACKAGE__->add_columns(qw/ id kanji q_code qc_type skip_misclass /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;