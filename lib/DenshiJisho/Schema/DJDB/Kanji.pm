package DenshiJisho::Schema::DJDB::Kanji;
use base qw/DBIx::Class/;
use JSON;
use Encode;
use Data::Dumper;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);

__PACKAGE__->table('kanji');
__PACKAGE__->add_columns(
  id  => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  kanji => {
    data_type => 'VARCHAR',
    size => 8,
    is_nullable => 0,
  },
  jlpt => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 1,
  },
  grade => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 0,
    default_value => 0,
  },
  strokes => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 1,
  },
  data => {
    data_type => 'TEXT',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->utf8_columns(qw/kanji data/);
__PACKAGE__->has_many('readings' => 'DenshiJisho::Schema::DJDB::KanjiReadings', 'kanji_id');
__PACKAGE__->has_many('meanings' => 'DenshiJisho::Schema::DJDB::KanjiMeanings', 'kanji_id');
__PACKAGE__->has_many('codes' => 'DenshiJisho::Schema::DJDB::KanjiCodes', 'kanji_id');
__PACKAGE__->has_many('kanji_radicals' => 'DenshiJisho::Schema::DJDB::KanjiRadicals', 'kanji_id');
__PACKAGE__->many_to_many('radicals', 'kanji_radicals', 'radical');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'kanji_index_on_kanji', fields => [qw/kanji/]);
    $sqlt_table->add_index(name => 'kanji_index_on_jlpt', fields => [qw/jlpt/]);
    $sqlt_table->add_index(name => 'kanji_index_on_grade', fields => [qw/grade/]);
    $sqlt_table->add_index(name => 'kanji_index_on_jlpt_grade', fields => [qw/jlpt grade/]);
}

__PACKAGE__->resultset_class('DenshiJisho::Schema::DJDB::KanjiRS');

__PACKAGE__->inflate_column('data', {
  inflate => sub { decode_json(encode_utf8(shift)) },
  deflate => sub { encode_json(shift) },
});

1;