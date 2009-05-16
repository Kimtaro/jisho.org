package DenshiJisho::Schema::DJDB::KanjiRadicals;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto UTF8Columns Core/);

__PACKAGE__->table('kanji_radicals');
__PACKAGE__->add_columns(
  id  => {
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
  radical_id => {
    data_type => 'INTEGER',
    size => 11,
    is_nullable => 0,
    is_foreign_key => 1,
  },
  kanji_grade => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 1,
    default_value => 0,
  },
  kanji_strokes => {
    data_type => 'INTEGER',
    size => 4,
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([qw/kanji_id radical_id/]);
__PACKAGE__->belongs_to(kanji => 'DenshiJisho::Schema::DJDB::Kanji', 'kanji_id');
__PACKAGE__->belongs_to(radical => 'DenshiJisho::Schema::DJDB::Radicals', 'radical_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    
    $sqlt_table->add_index(name => 'kanji_radicals_index_on_kanji_radical_grade', fields => [qw/kanji_id radical_id kanji_grade/]);
}

1;