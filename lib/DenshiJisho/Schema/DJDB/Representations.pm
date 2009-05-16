package DenshiJisho::Schema::DJDB::Representations;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('representations');
__PACKAGE__->add_columns(
  id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  word_id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_foreign_key => 1,
  },
  representation => {
    data_type => 'VARCHAR',
    size => 128,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->utf8_columns(qw/representation/);
__PACKAGE__->belongs_to('word' => 'DenshiJisho::Schema::DJDB::Words', 'word_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'rep_index_on_representation', fields => [qw/representation/]);
    $sqlt_table->add_index(name => 'rep_index_on_word_id_representation', fields => [qw/word_id representation/]);
}

1;