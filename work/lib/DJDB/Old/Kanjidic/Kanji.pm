package DJDB::Old::Kanjidic::Kanji;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji');
__PACKAGE__->add_columns(qw/ id literal grade object /);
__PACKAGE__->utf8_columns(qw/ literal /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('codepoints' => 'DJDB::Old::Kanjidic::Codepoint', 'kanji');
__PACKAGE__->has_many('radicals' => 'DJDB::Old::Kanjidic::Radical', 'kanji');
__PACKAGE__->has_many('stroke_counts' => 'DJDB::Old::Kanjidic::StrokeCount', 'kanji');
__PACKAGE__->has_many('variants' => 'DJDB::Old::Kanjidic::Variant', 'kanji');
__PACKAGE__->has_many('frequencies' => 'DJDB::Old::Kanjidic::Frequency', 'kanji');
__PACKAGE__->has_many('radical_names' => 'DJDB::Old::Kanjidic::RadicalName', 'kanji');
__PACKAGE__->has_many('dictionary_numbers' => 'DJDB::Old::Kanjidic::DictionaryNumber', 'kanji');
__PACKAGE__->has_many('query_codes' => 'DJDB::Old::Kanjidic::QueryCode', 'kanji');
__PACKAGE__->has_many('readings' => 'DJDB::Old::Kanjidic::Reading', 'kanji');
__PACKAGE__->has_many('meanings' => 'DJDB::Old::Kanjidic::Meaning', 'kanji');
__PACKAGE__->has_many('nanoris' => 'DJDB::Old::Kanjidic::Nanori', 'kanji');

1;