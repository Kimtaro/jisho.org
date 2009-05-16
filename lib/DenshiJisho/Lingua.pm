package DenshiJisho::Lingua;

use warnings;
use strict;
use utf8;
use Encode;
use Text::Balanced qw(extract_multiple extract_delimited);
use Text::MeCab;
use List::MoreUtils qw(uniq);

use Exporter 'import';
our @EXPORT = qw(
    romaji_to_kana
    fullwidth_to_halfwidth
    hiragana_to_katakana
    katakana_to_hiragana
    lemmatize_japanese
    get_tokens
    make_sql_wildcards
    make_regexp_wildcards
);

my $IDEOGRAPHIC_SPACE = qq(\x{3000});
my $RIGHT_DOUBLE_QUOTATION_MARK = qq(\x{201D});
my $H_SYLLABIC_N = q(ん);
my $H_SMALL_TSU = q(っ);

my $QUESTION_MARKS_RE = qq([\?\x{FF1F}]);
my $STARS_RE = qq([\*\x{FF0A}]);
my $ROMAJI_TO_KANA = {
  'a'   => 'あ', 'i'   => 'い',                'u'  => 'う',               'e'  => 'え',   'o'  => 'お',
  'ka'  => 'か', 'ki'  => 'き',                'ku' => 'く',               'ke' => 'け',   'ko' => 'こ',
  'ga'  => 'が', 'gi'  => 'ぎ',                'gu' => 'ぐ',               'ge' => 'げ',   'go' => 'ご',
  'sa'  => 'さ', 'si'  => 'し', 'shi' => 'し', 'su' => 'す',               'se' => 'せ',   'so' => 'そ',
  'za'  => 'ざ', 'zi'  => 'じ', 'ji'  => 'じ', 'zu' => 'ず',               'ze' => 'ぜ',   'zo' => 'ぞ',
  'ta'  => 'た', 'ti'  => 'ち', 'chi' => 'ち', 'tu' => 'つ', 'tsu'=> 'つ', 'te' => 'て',   'to' => 'と',
  'da'  => 'だ', 'di'  => 'ぢ',                'du' => 'づ', 'dzu'=> 'づ', 'de' => 'で',   'do' => 'ど',
  'na'  => 'な', 'ni'  => 'に',                'nu' => 'ぬ',               'ne' => 'ね',   'no' => 'の',
  'ha'  => 'は', 'hi'  => 'ひ',                'hu' => 'ふ', 'fu' => 'ふ', 'he' => 'へ',   'ho' => 'ほ',
  'ba'  => 'ば', 'bi'  => 'び',                'bu' => 'ぶ',               'be' => 'べ',   'bo' => 'ぼ',
  'pa'  => 'ぱ', 'pi'  => 'ぴ',                'pu' => 'ぷ',               'pe' => 'ぺ',   'po' => 'ぽ',
  'ma'  => 'ま', 'mi'  => 'み',                'mu' => 'む',               'me' => 'め',   'mo' => 'も',
  'ya'  => 'や',                               'yu' => 'ゆ',                               'yo' => 'よ',
  'ra'  => 'ら', 'ri'  => 'り',                'ru' => 'る',               're' => 'れ',   'ro' => 'ろ',
  'la'  => 'ら', 'li'  => 'り',                'lu' => 'る',               'le' => 'れ',   'lo' => 'ろ',
  'wa'  => 'わ', 'wi'  => 'うぃ',                                          'we' => 'うぇ', 'wo' => 'を',
  'wye' => 'ゑ', 'wyi' => 'ゐ', '-' => 'ー',

  'n'   => 'ん', 'nn'  => 'ん', "n'"=> 'ん',

  'kya' => 'きゃ', 'kyu' => 'きゅ', 'kyo' => 'きょ', 'kye' => 'きぇ', 'kyi' => 'きぃ',
  'gya' => 'ぎゃ', 'gyu' => 'ぎゅ', 'gyo' => 'ぎょ', 'gye' => 'ぎぇ', 'gyi' => 'ぎぃ',
  'kwa' => 'くぁ', 'kwi' => 'くぃ', 'kwu' => 'くぅ', 'kwe' => 'くぇ', 'kwo' => 'くぉ',
  'gwa' => 'ぐぁ', 'gwi' => 'ぐぃ', 'gwu' => 'ぐぅ', 'gwe' => 'ぐぇ', 'gwo' => 'ぐぉ',
  'qwa' => 'ぐぁ', 'gwi' => 'ぐぃ', 'gwu' => 'ぐぅ', 'gwe' => 'ぐぇ', 'gwo' => 'ぐぉ',

  'sya' => 'しゃ', 'syi' => 'しぃ', 'syu' => 'しゅ', 'sye' => 'しぇ', 'syo' => 'しょ',
  'sha' => 'しゃ',                  'shu' => 'しゅ', 'she' => 'しぇ', 'sho' => 'しょ',
  'ja'  => 'じゃ',                  'ju'  => 'じゅ', 'je'  => 'じぇ', 'jo'  => 'じょ',
  'jya' => 'じゃ', 'jyi' => 'じぃ', 'jyu' => 'じゅ', 'jye' => 'じぇ', 'jyo' => 'じょ',
  'zya' => 'じゃ', 'zyu' => 'じゅ', 'zyo' => 'じょ', 'zye' => 'じぇ', 'zyi' => 'じぃ',
  'swa' => 'すぁ', 'swi' => 'すぃ', 'swu' => 'すぅ', 'swe' => 'すぇ', 'swo' => 'すぉ',

  'cha' => 'ちゃ',                  'chu' => 'ちゅ', 'che' => 'ちぇ', 'cho' => 'ちょ',
  'cya' => 'ちゃ', 'cyi' => 'ちぃ', 'cyu' => 'ちゅ', 'cye' => 'ちぇ', 'cyo' => 'ちょ',
  'tya' => 'ちゃ', 'tyi' => 'ちぃ', 'tyu' => 'ちゅ', 'tye' => 'ちぇ', 'tyo' => 'ちょ',
  'dya' => 'ぢゃ', 'dyi' => 'ぢぃ', 'dyu' => 'ぢゅ', 'dye' => 'ぢぇ', 'dyo' => 'ぢょ',
  'tsa' => 'つぁ', 'tsi' => 'つぃ',                  'tse' => 'つぇ', 'tso' => 'つぉ',
  'tha' => 'てゃ', 'thi' => 'てぃ', 'thu' => 'てゅ', 'the' => 'てぇ', 'tho' => 'てょ',
  'twa' => 'とぁ', 'twi' => 'とぃ', 'twu' => 'とぅ', 'twe' => 'とぇ', 'two' => 'とぉ',
  'dha' => 'でゃ', 'dhi' => 'でぃ', 'dhu' => 'でゅ', 'dhe' => 'でぇ', 'dho' => 'でょ',
  'dwa' => 'どぁ', 'dwi' => 'どぃ', 'dwu' => 'どぅ', 'dwe' => 'どぇ', 'dwo' => 'どぉ',

  'nya' => 'にゃ', 'nyu' => 'にゅ', 'nyo' => 'にょ', 'nye' => 'にぇ', 'nyi' => 'にぃ',

  'hya' => 'ひゃ', 'hyi' => 'ひぃ', 'hyu' => 'ひゅ', 'hye' => 'ひぇ', 'hyo' => 'ひょ',
  'bya' => 'びゃ', 'byi' => 'びぃ', 'byu' => 'びゅ', 'bye' => 'びぇ', 'byo' => 'びょ',
  'pya' => 'ぴゃ', 'pyi' => 'ぴぃ', 'pyu' => 'ぴゅ', 'pye' => 'ぴぇ', 'pyo' => 'ぴょ',
  'fa'  => 'ふぁ', 'fi'  => 'ふぃ',                  'fe'  => 'ふぇ', 'fo'  => 'ふぉ',
  'fwa' => 'ふぁ', 'fwi' => 'ふぃ', 'fwu' => 'ふぅ', 'fwe' => 'ふぇ', 'fwo' => 'ふぉ',
  'fya' => 'ふゃ', 'fyi' => 'ふぃ', 'fyu' => 'ふゅ', 'fye' => 'ふぇ', 'fyo' => 'ふょ',
  
  'mya' => 'みゃ', 'myi' => 'みぃ', 'myu' => 'みゅ', 'mye' => 'みぇ', 'myo' => 'みょ',

  'rya' => 'りゃ', 'ryi' => 'りぃ', 'ryu' => 'りゅ', 'rye' => 'りぇ', 'ryo' => 'りょ',
  'lya' => 'りゃ', 'lyu' => 'りゅ', 'lyo' => 'りょ', 'lye' => 'りぇ', 'lyi' => 'りぃ',

  'va'  => 'ゔぁ', 'vi'  => 'ゔぃ', 'vu'  => 'ゔ',   've'  => 'ゔぇ',  'vo' => 'ゔぉ',
  'vya' => 'ゔゃ', 'vyi' => 'ゔぃ', 'vyu' => 'ゔゅ', 'vye' => 'ゔぇ', 'vyo' => 'ゔょ',
  'wha' => 'うぁ', 'whi' => 'うぃ', 'ye'  => 'いぇ', 'whe' => 'うぇ', 'who' => 'うぉ',
  
  'xa'  => 'ぁ', 'xi'   => 'ぃ', 'xu'  => 'ぅ', 'xe'  => 'ぇ', 'xo'   => 'ぉ',
  'xya' => 'ゃ', 'xyu'  => 'ゅ', 'xyo' => 'ょ',
  'xtu' => 'っ', 'xtsu' => 'っ',
  'xka' => 'ゕ', 'xke'  => 'ゖ', 'xwa' => 'ゎ',
  
  '@@' => '　', '#[' => '「', '#]' => '」', '#,' => '、', '#.' => '。', '#/' => '・',
  
};

sub romaji_to_kana {
  my ( $romaji ) = @_;  

  # Change m to n before p and b
  $romaji =~ s/m([BbPp])/n$1/g;
  $romaji =~ s/M([BbPp])/N$1/g;

  my $kana = q();
  ROMAJI: while( length($romaji) ) {
    foreach my $length (3, 2, 1) {
      my $mora;
      my $for_removal = $length;
      my $for_conversion = substr($romaji, 0, $length);
      my $is_upper = ($for_conversion =~ /^\p{IsUpper}/);
      $for_conversion = lc($for_conversion);

      if ( $for_conversion =~ m/nn[aiueo]/ ) {
        # nna should kanafy to んな instead of んあ
        # This is what people expect for words like konna, anna, zannen
        $mora = $H_SYLLABIC_N;
        $for_removal = 1;
      }
      elsif ( $ROMAJI_TO_KANA->{$for_conversion} ) {
        # Generic cases
        $mora = $ROMAJI_TO_KANA->{$for_conversion};
      }
      elsif ( $for_conversion eq 'tch'
      || ( $length == 2 && $for_conversion =~ /([kgsztdnbpmyrlw])\1/ )
      ) {
        # tch and double-consonants for small tsu 
        $mora = $H_SMALL_TSU;
        $for_removal = 1;
      }

      if ( $mora ) {
        $kana .= $is_upper ? hiragana_to_katakana($mora) : $mora;
        substr($romaji, 0, $for_removal, q());
        next ROMAJI;
      }
      elsif ( $length == 1 ) {
        # Nothing found
        $kana .= $for_conversion;
        substr($romaji, 0, 1, q());
      }
    }
  }
  
  return $kana;
}

sub fullwidth_to_halfwidth {
  my ( $full ) = @_;
  my $half = q();
  
  $half = join q(), map {
    my $o = ord $_;
    $o >= 65281 && $o <= 65374
      ? chr($o - 65248)
      : $o == 12288
        ? chr($o - 12256)
        : $_;
  } split(q(), $full)
}

sub hiragana_to_katakana {
  my ( $hira ) = @_;
  my $kata     = q();
  
  while( length($hira) ) {
    my $char  = substr($hira, 0, 1, "");
    my $ord    = ord $char;

    if( $ord >= 12353 and $ord <= 12438 ) {
      $kata .= chr($ord + 96);
    }
    else {
      $kata .= $char;
    }
  }

  return $kata;
}

sub katakana_to_hiragana {
  my ( $kata )    = @_;
  my $hira         = q();

  while( length($kata) ) {
    my $char  = substr($kata, 0, 1, "");
    my $ord    = ord $char;

    if( $ord >= 12449 and $ord <= 12534 ) {
      $hira .= chr($ord - 96);
    }
    else {
      $hira .= $char;
    }
  }
  
  return $hira;
}

sub lemmatize_japanese {
  my ($text) = @_;
  
  return unless $text;
  
  my $mecab = Text::MeCab->new;
  my $lemma;
  
  for (my $node = $mecab->parse(encode_utf8($text)); $node; $node = $node->next) {
    my @features  = split(q(,), $node->feature);
    my $hinshi    = decode_utf8($features[0]);
    my $deinflected = decode_utf8($features[6]);
    
    if (substr($deinflected, 0, 1) eq substr($text, 0, 1) and ($hinshi eq '動詞' or $hinshi eq '形容詞')) {
      $lemma = $deinflected;
      last;
    }
  }
    
  return $lemma;
}

sub get_tokens {
  my ( $text ) = @_;
  my @return_tokens;
  
  my @tokens = extract_multiple($text, [
    { Quote => sub { extract_delimited($_[0], q/"/) } },
    { Quote => sub { extract_delimited($_[0], qq/$RIGHT_DOUBLE_QUOTATION_MARK/) } },
    qr/[^\s$IDEOGRAPHIC_SPACE]+/,
  ], undef, 1);
  
  foreach my $token (@tokens) {
    if (ref $token eq 'Quote') {
      $$token =~ s/^.(.*).$/$1/;
      push @return_tokens, $$token;
    }
    else {
      push @return_tokens, $token;
    }
  }
  
  return @return_tokens;
}

sub make_sql_wildcards {
    my ( $tokens, $pre, $post ) = @_;
    my @result;
    
    $pre ||= q();
    $post ||= q();
    
    foreach my $token ( @{$tokens} ) {
    if ($token =~ m/ $QUESTION_MARKS_RE | $STARS_RE /x) {
        $token =~ s/ ([%_]) /\\$1/gx;
      $token =~ s/ $STARS_RE /%/gx;
      $token =~ s/ $QUESTION_MARKS_RE /_/gx;
      push @result, $token;
    }
    else {
      push @result, "$pre$token$post";
    }
  }
  
  return @result;
}

sub make_regexp_wildcards {
    my ( $tokens, $language ) = @_;
    my @regexps;
    
    $language ||= q(ja);
    
    foreach my $token ( @{$tokens} ) {
        my @modifieds;
        
    if ( $language eq q(en) ) {
        if ( $token !~ m/ $QUESTION_MARKS_RE | $STARS_RE /x ) {
            $token = qq{\\b$token\\b};
          }
          push @modifieds, $token;
    }
    
    if ( $language eq q(ja) ) {
        push @modifieds, $token;
          push @modifieds, hiragana_to_katakana($token);
    }
    
    push @regexps, map { qr{$_} } map { s{\s}{\\s}gx; split /$QUESTION_MARKS_RE+ | $STARS_RE+/x; } @modifieds;
  }
    
    @regexps = uniq(@regexps);
  return @regexps;
}

1;
