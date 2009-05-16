package DJDB::Old::Kanjidic::DictionaryNumber;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('kanji_dic_number');
__PACKAGE__->add_columns(qw/ id kanji dic_ref dr_type dj_sort_order m_vol m_page /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;