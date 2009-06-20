package DenshiJisho::Schema::DJDB::WordsRS;
use base qw/DBIx::Class::ResultSet Class::Accessor::Fast/;
use DenshiJisho::Lingua;
use Data::Page::Balanced;
use Data::Dumper;
use utf8;

__PACKAGE__->mk_accessors(qw/_dictionaries/);

sub find_words_with_dictionary_counts {
  my ( $self, $options ) = @_;
  
  my %dictionary_counts = map { $_ => 0 } @{$self->dictionaries};
  my $all_words = $self->_get_word_ids($options);
  
  if ( ref $all_words eq 'ARRAY' ) {
    return( ([], [], \%dictionary_counts) );
  }
  
  foreach my $dictionary (keys %dictionary_counts) {
    $dictionary_counts{$dictionary} = $all_words->count({source => $dictionary});
  }
  
  if ( !defined $dictionary_counts{$options->{source}} || $dictionary_counts{$options->{source}} == 0 ) {
    return( ([], [], \%dictionary_counts) );
  }

  my $pager = Data::Page::Balanced->new({
    current_page => $options->{page},
    total_entries => $dictionary_counts{$options->{source}},
    entries_per_page => $options->{limit} || $dictionary_counts{$options->{source}},
  });
  
  my $words_limited = $all_words->search(
    source => $options->{source},
    {select => [qw/me.data me.id/]}
  )->slice($pager->first-1, $pager->last-1);
    
  return( ($words_limited, $pager, \%dictionary_counts) );
}

sub _get_word_ids {
  my ( $self, $options ) = @_;
  
  # Make sure we don't do wildcard-only searches
	if (   (defined $options->{japanese} && $options->{japanese} =~ m/^[*?\s]+$/)
		  || (defined $options->{gloss} && $options->{gloss} =~ m/^[*?\s]+$/) ) {
		return [];
	}
	
	# Special JMdict convention for references
	$options->{japanese} =~ s/・/ /g;
  
  # Set up search terms
  my @japanese_tokens = get_tokens( romaji_to_kana($options->{japanese}) );
     @japanese_tokens = make_sql_wildcards(\@japanese_tokens, q{}, q{%});
  
  my @gloss_tokens = get_tokens($options->{gloss});
  my @gloss_tokens_re = make_sql_wildcards(\@gloss_tokens, q{[[:<:]]}, q{[[:>:]]});
     @gloss_tokens = make_sql_wildcards(\@gloss_tokens, q{%}, q{%});
  
  my @order_bys;
  my $joins = [qw/representations meanings/];
  my $japanese_count = scalar @japanese_tokens;
  my $gloss_count = scalar @gloss_tokens;
  my $where = {};
  my @gloss_conds;
  my @jap_conds;
  
#	@{$c->stash->{markup}->{japanese_tokens}} = make_regexp_wildcards(\@japanese_tokens, q(ja));
#	@{$c->stash->{markup}->{gloss_tokens}} = make_regexp_wildcards(\@gloss_tokens, q(en));

  $where->{q{meanings.language}} = $options->{language};

  if ( $options->{common_only} ) {
    $where->{q{me.has_common}} = 1;
  }
  
  if ( $gloss_count > 0 ) {
    for ( my $i = $0; $i < $gloss_count; $i++ ) {
      push @gloss_conds, {'like' => $gloss_tokens[$i]};
      push @gloss_conds, {'regexp' => $gloss_tokens_re[$i]};
    }
    $where->{q{meanings.meaning}} = ['-and' => @gloss_conds];
  }
  warn Dumper $where;
  
  if ( $japanese_count > 0 ) {
    foreach my $token (@japanese_tokens) {
      warn Dumper $token;
      push @jap_conds, { 'IN' =>
      #[1,2]
      $self->search_related_rs('representations', {representation => {-like => $token}}, {select => [qw/me.id/]})->as_query
      #"(SELECT word_id FROM representations WHERE representation LIKE '$token')"
      };
      warn Dumper \@jap_conds;
    }
    $where->{q{me.id}} = ['-and' => @jap_conds];
  }

  warn Dumper $where;
  return $self->search($where, {
    select => [qw/me.id/],
    join => $joins,
    order_by => q(LENGTH(representations.representation)),
    group_by => [qw/me.id/],
  });
}

sub dictionaries {
  my ( $self ) = @_;

  if ( !defined $self->_dictionaries ) {
    $self->_dictionaries( [$self->search({}, {group_by => 'source'})->get_column('source')->all] );
  }

  return $self->_dictionaries;
}

1;