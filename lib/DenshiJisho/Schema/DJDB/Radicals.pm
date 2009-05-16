package DenshiJisho::Schema::DJDB::Radicals;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);

__PACKAGE__->table('radicals');
__PACKAGE__->add_columns(
  id  => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  radical => {
    data_type => 'VARCHAR',
    size => 4,
    is_nullable => 0,
  },
  number => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 0,
  },
  strokes => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 0,
  },
);

__PACKAGE__->utf8_columns(qw/ radical /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('kanji_radicals' => 'DenshiJisho::Schema::DJDB::KanjiRadicals', 'radical_id');
__PACKAGE__->many_to_many('kanji', 'kanji_radicals', 'kanji');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'radicals_index_on_radical_number_strokes', fields => [qw/radical number strokes/]);
    $sqlt_table->add_index(name => 'radicals_index_on_radical', fields => [qw/radical/]);
}

1;