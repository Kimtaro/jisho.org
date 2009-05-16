package DenshiJisho::Schema::DJDB::Meanings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('meanings');
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
  language => {
    data_type => 'VARCHAR',
    size => 3,
    default => 'eng',
    is_nullable => 0,    
  },
  meaning => {
    data_type => 'VARCHAR',
    size => 128,
    is_nullable => 0,
  },
);

__PACKAGE__->utf8_columns(qw/meaning/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('word' => 'DenshiJisho::Schema::DJDB::Words', 'word_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'meanings_index_on_language_meaning', fields => [qw/language meaning/]);
    $sqlt_table->add_index(name => 'meanings_index_on_word_id_language_meaning', fields => [qw/word_id language meaning/]);
}

1;