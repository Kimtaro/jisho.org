package DenshiJisho::Schema::DJDB::Words;
use base qw/DBIx::Class/;
use JSON;
use Encode;
use Data::Dumper;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);

__PACKAGE__->table('words');
__PACKAGE__->add_columns(
  id  => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  source => {
    data_type => 'VARCHAR',
    size => 16,
    is_nullable => 0,
  },
  source_id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 1,
  },
  has_common => {
    data_type => 'INTEGER',
    size => 1,
    is_nullable => 1,    
  },
  data => {
    data_type => 'TEXT',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->utf8_columns(qw/data/);
__PACKAGE__->has_many('representations' => 'DenshiJisho::Schema::DJDB::Representations', 'word_id');
__PACKAGE__->has_many('meanings' => 'DenshiJisho::Schema::DJDB::Meanings', 'word_id');
__PACKAGE__->has_many('tags' => 'DenshiJisho::Schema::DJDB::WordTags', 'word_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'words_index_on_source', fields => [qw/source/]);
    $sqlt_table->add_index(name => 'words_index_on_source_source_id', fields => [qw/source source_id/]);
    $sqlt_table->add_index(name => 'words_index_on_source_has_common', fields => [qw/source has_common/]);
}

__PACKAGE__->resultset_class('DenshiJisho::Schema::DJDB::WordsRS');

__PACKAGE__->inflate_column('data', {
  inflate => sub { decode_json(encode_utf8(shift)) },
  deflate => sub { encode_json(shift) },
});

1;