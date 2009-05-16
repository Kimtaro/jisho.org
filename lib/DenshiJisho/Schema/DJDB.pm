package DenshiJisho::Schema::DJDB;
use base qw/DBIx::Class::Schema/;
use Data::Dumper;

our $VERSION = '1.0';

__PACKAGE__->load_classes(qw/
  Words
  Representations
  Meanings
  WordTags
  
  Kanji
  KanjiReadings
  KanjiMeanings
  KanjiCodes
  KanjiRadicals
  
  Radicals
/);

1;