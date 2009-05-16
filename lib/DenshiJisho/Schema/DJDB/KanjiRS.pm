package DenshiJisho::Schema::DJDB::KanjiRS;
use base qw/DBIx::Class::ResultSet Class::Accessor::Fast/;
use DenshiJisho::Lingua;
use Data::Page::Balanced;
use Data::Dumper;
use utf8;

sub find_by_all {
  my ( $self, $options ) = @_;
  
  my $all_kanji = $self->_get_kanji_ids($options);

  my $pager = Data::Page::Balanced->new({
    current_page => $options->{page},
    total_entries => $all_kanji->count,
    entries_per_page => $options->{limit} || $all_kanji->count,
  });
  
  my $kanji = $all_kanji->search(undef, {
    select => [qw/me.data me.id me.grade me.kanji/]
  })->slice($pager->first-1, $pager->last-1);
    
  return( ($kanji, $pager) );
}

sub _get_kanji_ids {
  my ( $self, $options ) = @_;
  
  $options->{rt} = [qw/ja_kun ja_on/] if $options->{rt} eq 'japanese';
  
  # Make sure we don't do wildcard-only searches
	if (   (defined $options->{reading} && $options->{reading} =~ m/^[*?\s]+$/)
		  || (defined $options->{meaning} && $options->{meaning} =~ m/^[*?\s]+$/)
		  || (defined $options->{code} && $options->{code} =~ m/^[*?\s]+$/) ) {
		return [];
	}
	
  # Set up search terms
  my @reading_tokens = get_tokens( romaji_to_kana($options->{reading}) );
     @reading_tokens = make_sql_wildcards(\@reading_tokens, q{}, q{%});
  
  my @meaning_tokens = get_tokens($options->{meaning});
  my @meaning_tokens_re = make_sql_wildcards(\@meaning_tokens, q{[[:<:]]}, q{[[:>:]]});
     @meaning_tokens = make_sql_wildcards(\@meaning_tokens, q{%}, q{%});
  
  my $joins = [qw/readings meanings codes/];
  my $meaning_count = scalar @meaning_tokens;
  my $reading_count = scalar @reading_tokens;
  my $where = {};
  my @reading_conds;
  my @meaning_conds;

  if ( $options->{jy_only} ) {
    $where->{q{me.grade}} = {'>' => 0};
  }
  
  if ( $meaning_count > 0 ) {
    for ( my $i = $0; $i < $meaning_count; $i++ ) {
      push @meaning_conds, {'like' => $meaning_tokens[$i]};
      push @meaning_conds, {'regexp' => $meaning_tokens_re[$i]};
    }
    $where->{q{meanings.meaning}} = ['-and' => @meaning_conds];
    $where->{q{meanings.language}} = $options->{mt};
  }
  
  if ( $reading_count > 0 ) {    
    foreach my $token (@reading_tokens) {
      push @reading_conds, {'like' => $token};
    }
    $where->{q{readings.reading}} = ['-and' => @reading_conds];
    $where->{q{readings.type}} = $options->{rt};
  }
  
  if ( $options->{code} ) {
    $where->{q{codes.value}} = $options->{code};
    $where->{q{codes.type}} = $options->{ct};
  }

  #warn Dumper $options, $where;
  return $self->search($where, {
    select => [qw/me.id/],
    join => $joins,
    order_by => q(me.strokes, me.grade, me.jlpt),
    group_by => [qw/me.id/],
  });
}

1;