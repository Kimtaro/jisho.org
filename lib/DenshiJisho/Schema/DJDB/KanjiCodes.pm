package DenshiJisho::Schema::DJDB::KanjiCodes;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);
__PACKAGE__->table('kanji_codes');
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
  section => {
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
__PACKAGE__->belongs_to('kanji' => 'DenshiJisho::Schema::DJDB::Kanji', 'kanji_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'kc_index_on_type_value', fields => [qw/type value/]);
    $sqlt_table->add_index(name => 'kc_index_on_section_type_value', fields => [qw/section type value/]);
}

1;