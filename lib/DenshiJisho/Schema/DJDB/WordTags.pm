package DenshiJisho::Schema::DJDB::WordTags;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('word_tags');
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
  group => {
    data_type => 'VARCHAR',
    size => 16,
    is_nullable => 1,
  },
  type => {
    data_type => 'VARCHAR',
    size => 16,
    is_nullable => 0,
  },
  value => {
    data_type => 'VARCHAR',
    size => 16,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->utf8_columns(qw/value/);
__PACKAGE__->belongs_to('word' => 'DenshiJisho::Schema::DJDB::Words', 'word_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'wtag_index_on_type', fields => [qw/type/]);
    $sqlt_table->add_index(name => 'wtag_index_on_type_value', fields => [qw/type value/]);
    $sqlt_table->add_index(name => 'wtag_index_on_group_type_value', fields => [qw/group type value/]);
}

1;