package DJDB;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/
	Radk
	
	Old::Tanaka
	
	Old::Compdic
	Old::Compdic::Tag
	Old::Compdic::Text::Jap
	Old::Compdic::Text::Eng
	
	Old::Edict
	Old::Edict::Tag
	Old::Edict::Text::Jap
	Old::Edict::Text::Eng
	
	Old::Engscidic
	Old::Engscidic::Tag
	Old::Engscidic::Text::Jap
	Old::Engscidic::Text::Eng
	
	Old::Enamdic
	Old::Enamdic::Tag
	Old::Enamdic::Text::Jap
	Old::Enamdic::Text::Eng
	
	Old::Kanjidic::Codepoint
	Old::Kanjidic::DictionaryNumber
	Old::Kanjidic::Frequency
	Old::Kanjidic::Kanji
	Old::Kanjidic::Meaning
	Old::Kanjidic::Nanori
	Old::Kanjidic::QueryCode
	Old::Kanjidic::Radical
	Old::Kanjidic::RadicalName
	Old::Kanjidic::Reading
	Old::Kanjidic::StrokeCount
	Old::Kanjidic::Variant
	
	JMdict::Entry
	JMdict::Entry::Dial
	JMdict::Entry::Lang
	JMdict::Gloss
	JMdict::Kanji
	JMdict::Kanji::Info
	JMdict::Kanji::Prio
	JMdict::KanjiReading
	JMdict::Reading
	JMdict::Reading::Info
	JMdict::Reading::Prio
	JMdict::Sense
	JMdict::Sense::Ant
	JMdict::Sense::Field
	JMdict::Sense::Misc
	JMdict::Sense::Pos
	JMdict::Sense::Stagk
	JMdict::Sense::Stagr
	JMdict::Sense::Xref
/);

# JMdict::Entry
# JMdict::Entry::Dial
# JMdict::Entry::Lang
# JMdict::Gloss
# JMdict::Kanji
# JMdict::Kanji::Info
# JMdict::Kanji::Prio
# JMdict::KanjiReading
# JMdict::Reading
# JMdict::Reading::Info
# JMdict::Reading::Prio
# JMdict::Sense
# JMdict::Sense::Ant
# JMdict::Sense::Field
# JMdict::Sense::Misc
# JMdict::Sense::Pos
# JMdict::Sense::Stagk
# JMdict::Sense::Stagr
# JMdict::Sense::Xref

1;