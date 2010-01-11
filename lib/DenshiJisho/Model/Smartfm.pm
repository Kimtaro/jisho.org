package DenshiJisho::Model::Smartfm;

use strict;
use warnings;
use base 'Catalyst::Model';
use LWP::UserAgent;
use JSON ();
use Data::Dumper;
use URI::Escape qw(uri_escape_utf8);

sub new {
  my $self = shift;

  $self->config(
    iso_639_2_for => {
      en => 'eng',
      de => 'ger',
      fr => 'fre',
      ru => 'rus',
    },
    rfc_3066_for => {
      eng => 'en',
      ger => 'de',
      fre => 'fr',
      rus => 'ru',
    }
  );
  
  return $self->next::method(@_);
}

sub items {
  my ($self, $cue, $options) = @_;
  $options->{page} ||= 1;
  $options->{limit} ||= 1;
  $cue = uri_escape_utf8($cue);
  my $lang = $self->config->{rfc_3066_for}->{$options->{language}};
  my $url = "http://api.smart.fm/items/matching/$cue.json?&per_page=100&language=ja&translation_language=$lang&api_key=" . $self->config->{smartfm_api_key};
  
  warn Dumper $url;
  
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get($url);
  my $data;
  
  if ($response->is_success) {
    $data = $response->decoded_content;
  }
  else {
    warn $response->status_line;
    $data = {};
  }
  
  my $json = new JSON;
  my $o = $json->decode($data);

  return $self->_to_words_json($o);
}

sub _to_words_json {
  my ($self, $items) = @_;
  my @words = ();
  
  warn Dumper $items;
  
  foreach my $item (@{$items}) {
    my $responses = {};
    foreach my $response (@{$item->{responses}}) {
      $responses->{$response->{type}} = {
        text => $response->{text},
        language => $response->{language},
      };
    }

    my $word = {
      source => 'smartfm',
      source_id => $item->{id},
      data => {
        senses => [{
          glosses => [{
            type => $self->config->{iso_639_2_for}->{$responses->{meaning}->{language}},
            value => $responses->{meaning}->{text}
          }],
          tags => [{
            type => 'pos',
            tag => $item->{cue}->{part_of_speech}
          }]
        }],
        reading_groups => [{
          representations => ($responses->{character} ? [{
              representation => $responses->{character}->{text},
              is_common => 0,
              tags => 'null',
            }] : undef),
          readings => [$item->{cue}->{text}],
          is_common => 0,
        }],
      },
    };
    
    push @words, $word;
  }
  
  warn Dumper \@words;
  
  return {all => \@words};
}

sub sentences {
  my ($self, $japanese, $english, $options) = @_;
  $options->{page} ||= 1;
  $options->{limit} ||= 1;
  $japanese = uri_escape_utf8($japanese);
  $english = uri_escape_utf8($english);
  my $url = "http://api.smart.fm/sentences/matching/$japanese%20$english.json?&per_page=100&language=ja&translation_language=en&api_key=" . $self->config->{smartfm_api_key};
  
  warn Dumper $url;
  
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get($url);
  my $data;
  
  if ($response->is_success) {
    $data = $response->decoded_content;
  }
  else {
    warn $response->status_line;
    $data = {};
  }
  
  my $json = new JSON;
  my $o = $json->decode($data);

  return $self->_to_sentences_json($o);
  
}

sub _to_sentences_json {
  my ($self, $sentences) = @_;
  
}

1;
