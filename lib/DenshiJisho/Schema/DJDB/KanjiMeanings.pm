package DenshiJisho::Schema::DJDB::KanjiMeanings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji_meanings');
__PACKAGE__->add_columns(
  id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  kanji_id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_foreign_key => 1,
  },
  language => {
    data_type => 'VARCHAR',
    size => 4,
    is_nullable => 0,
  },
  meaning => {
    data_type => 'VARCHAR',
    size => 128,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DenshiJisho::Schema::DJDB::Kanji', 'kanji_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'km_index_on_language_meaning', fields => [qw/language meaning/]);
}

1;