package DenshiJisho::Schema::DJDB::KanjiReadings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji_readings');
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
  type => {
    data_type => 'VARCHAR',
    size => 16,
    is_nullable => 0,
  },
  reading => {
    data_type => 'VARCHAR',
    size => 64,
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('kanji' => 'DenshiJisho::Schema::DJDB::Kanji', 'kanji_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'kr_index_on_type_reading', fields => [qw/type reading/]);
}

1;