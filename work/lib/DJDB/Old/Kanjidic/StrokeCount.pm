package DJDB::Old::Kanjidic::StrokeCount;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('kanji_stroke_count');
__PACKAGE__->add_columns(qw/ id kanji stroke_count /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DJDB::Old::Kanjidic::Kanji');

1;