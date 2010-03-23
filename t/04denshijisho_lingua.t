use strict;
use warnings;
use utf8;
use Test::More tests => 39;

my $KATAKANA = "ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴヵヶ";
my $HIRAGANA = "ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをんゔゕゖ";
my $FULLWIDTH = '！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ［＼］＾＿｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～　';
my $HALFWIDTH = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ';


BEGIN { use_ok 'DenshiJisho::Lingua' }

# fullwidth_to_halfwidth
{
  is( fullwidth_to_halfwidth($FULLWIDTH), $HALFWIDTH )
}

# romaji_to_kana
{
    # Hiragana
    is( romaji_to_kana('kanadesu'),     'かなです' );
    is( romaji_to_kana('kosoado'),      'こそあど' );
    is( romaji_to_kana('konna'),        'こんな' );
    is( romaji_to_kana('shimbun'),      'しんぶん' );
    is( romaji_to_kana('simpai'),       'しんぱい' );
    is( romaji_to_kana('wha'),          'うぁ' );
    is( romaji_to_kana('katchatta'),    'かっちゃった' );
    is( romaji_to_kana('kawwaiixi'),    'かっわいいぃ' );
    is( romaji_to_kana('ottosei'),      'おっとせい' );
    is( romaji_to_kana('acchi'),        'あっち' );

    # Katakana
    is( romaji_to_kana('KANADESU'),     'カナデス' );
    is( romaji_to_kana('KOSOADO'),      'コソアド' );
    is( romaji_to_kana('KONNA'),        'コンナ' );
    is( romaji_to_kana('SHIMBUN'),      'シンブン' );
    is( romaji_to_kana('SIMPAI'),       'シンパイ' );
    is( romaji_to_kana('WHA'),          'ウァ' );
    is( romaji_to_kana('KATCHATTA'),    'カッチャッタ' );
    is( romaji_to_kana('KAWWAIIXI'),    'カッワイイィ' );
    is( romaji_to_kana('OTTOSEI'),      'オットセイ' );
    is( romaji_to_kana('ACCHI'),        'アッチ' );
    is( romaji_to_kana('KATAKANA desu'),'カタカナ です' );

    # Non-Japanese
    is( romaji_to_kana('this is some english'), 'てぃs いs そめ えんgりsh' );
}

# hiragana_to_katakana
{
    is( hiragana_to_katakana($HIRAGANA), $KATAKANA );
}

# katakana_to_hiragana
{
    is( katakana_to_hiragana($KATAKANA), $HIRAGANA );
}

# get_tokens
{
    is_deeply( [get_tokens('normal text')],    ['normal', 'text'] );
    is_deeply( [get_tokens('"normal text"')],  ['normal text'] );
    is_deeply( [get_tokens('”normal text”')],  ['normal text'] );
    is_deeply( [get_tokens('normal　text')],    ['normal', 'text'] );
    is_deeply( [get_tokens('normal text with "a multiword token"')], ['normal', 'text', 'with', 'a multiword token'] );
    is_deeply( [get_tokens('normal　text　with　”a multiword token”')], ['normal', 'text', 'with', 'a multiword token'] );
}

# lemmatize_japanese
{
    is( lemmatize_japanese('来る'),   '来る' );
    is( lemmatize_japanese('来た'),   '来る' );
    is( lemmatize_japanese('来られる'), '来る' );
}

# make_sql_wildcards
{
    my @simple_tokens = qw/some tokens/;
    my @complicated_tokens = qw/some* *token ?wo?ds%_/;
    
    is_deeply( [make_sql_wildcards(\@simple_tokens)],           ['some', 'tokens'] );
    is_deeply( [make_sql_wildcards(\@simple_tokens, '', '%')],  ['some%', 'tokens%'] );
    is_deeply( [make_sql_wildcards(\@simple_tokens, '%', '%')], ['%some%', '%tokens%'] );
    is_deeply( [make_sql_wildcards(\@complicated_tokens)],      ['some%', '%token', '_wo_ds\%\_'] );
}
