package DJDB::Radk;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('radk');
__PACKAGE__->add_columns(qw/ id radical_number radical_strokes radical kanji kanji_strokes kanji_grade kanji_grade_sort /);
__PACKAGE__->utf8_columns(qw/ radical kanji /);
__PACKAGE__->set_primary_key('id');

1;