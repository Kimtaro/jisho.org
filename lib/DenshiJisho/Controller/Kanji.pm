package DenshiJisho::Controller::Kanji;

use strict;
use base 'Catalyst::Controller';
use Encode;
use utf8;
use List::Compare;
use Data::Dumper;
use SQL::Abstract;
use Array::Unique;
use Unicode::Japanese;
use URI::Escape qw(uri_escape uri_escape_utf8);
use DenshiJisho::Lingua;

=head1 NAME

DenshiJisho::Controller::Kanji - Catalyst component

=head1 SYNOPSIS

See L<DenshiJisho>

=head1 DESCRIPTION

Catalyst component.

=head1 METHODS

=over 4

=item default

=cut

sub auto : Private {
  my ( $self, $c ) = @_;

	# We got parameters for kanji details, which takes precedence
	if ( $c->req->params->{reading} =~ m/\p{Han}/) {
		if ( $c->flavour eq 'j_mobile' ) {
			# Convert to shift_jis for j_mobile
			$c->res->redirect('/kanji/details/'
				. encode('shift_jis', $c->req->params->{reading})
			);
		}
		elsif ( $c->flavour eq 'iphone' ) {
		    $c->res->redirect('/kanji/details/'
				. encode_utf8($c->req->params->{reading})
				. '?flavour=iphone'
			);
		}
		else {
			$c->res->redirect('/kanji/details/'
				. uri_escape_utf8($c->req->params->{reading})
			);
		}
		$c->detach;
	}
	
	$c->persistent_form('kanji', [qw(rt ct mt jy_only)]);
	
	# Convenient stuff
	$c->req->params->{reading} = romaji_to_kana($c->req->params->{reading})
	  if $c->req->params->{rt} eq 'japanese';
	  
	$c->req->params->{code} = fullwidth_to_halfwidth($c->req->params->{code});
	$c->req->params->{reading} = fullwidth_to_halfwidth($c->req->params->{reading});
	$c->req->params->{meaning} = fullwidth_to_halfwidth($c->req->params->{meaning});
	
	# Check limit
	$c->stash->{limit} = $c->req->param('nolimit') eq 'on' ? 0 : $c->config->{result_limit};
	
	# Smart switching to the correct rt, mt and ct based on what the user inputs
	if ($c->req->params->{code} =~ m/^\d+-\d+-\d+$/) {
		# SKIP
		$c->req->params->{ct} = 'skip';
	}
	
	1;
}

sub index : Private {
  my ( $self, $c ) = @_;

  $c->stash->{template} = 'kanji/index.tt';
	$c->stash->{page} = 'kanji';
	
	return unless $c->req->param('reading')
	           || $c->req->param('meaning')
	           || $c->req->param('code');

  my ($kanji, $pager) = $c->model('DJDB::Kanji')->find_by_all({
    rt => $c->req->params->{rt},
    ct => $c->req->params->{ct},
    mt => $c->req->params->{mt},
    reading => $c->req->params->{reading},
    code => $c->req->params->{code},
    meaning => $c->req->params->{meaning},
    jy_only => $c->req->params->{jy_only} eq 'on' ? 1 : 0,
    page => $c->req->param('page') || 1,
	  limit => $c->stash->{limit},
  });
			
	# If no kanji found, suggest other searches
	if ($pager->total_entries == 0) {
		if ($c->req->params->{rt} eq 'japanese') {
			my $key				  = $c->req->params->{reading};
			my $key_uj			= Unicode::Japanese->new($key);
			my $key_euc			= $key_uj->euc;
			my $key_sjis		= $key_uj->sjis;

			$c->stash->{suggest}->{key}			  = $key;
			$c->stash->{suggest}->{key_euc}		= uri_escape( $key_euc );
			$c->stash->{suggest}->{key_sjis}	= uri_escape( $key_sjis );
		}
	}
	
	# Show the result
	if ( $c->flavour() eq q{iphone} ) {
	  $c->stash->{json} = {
	    type => 'kanji',
	    kanji => $self->inflate_result_for_iphone($c),
	    total => $pager->total_entries,
	    pager => {
	      last_page => $c->stash->{pager}->last_page,
	      current_page => $c->stash->{pager}->current_page,
	    }
	  };
	  
    $c->stash(current_view => 'JSON');
	}
	else {
	  $c->stash->{pager} = $pager;
	  $c->stash->{kanji} = $kanji;
	  $c->stash->{template} = 'kanji/result.tt';
	}
	
}

sub inflate_result_for_iphone {
	my ( $self, $c ) = @_;
	
	my @result;
	
	foreach my $kanji ( @{$c->stash->{result}->{kanjis}} ) {
	    my $local = {};
	    
	    $local->{literal} = $kanji->literal();
	    $local->{grade} = defined $kanji->grade() ? $kanji->grade() : 0;
	    
	    foreach my $reading ( $kanji->readings()->all() ) {
	        if ( $reading->r_type() eq 'ja_on' || $reading->r_type() eq 'ja_kun' ) {
	            push @{$local->{readings}}, $reading->reading();
	        }
	    }
	    
	    foreach my $meaning ( $kanji->meanings()->all() ) {
	        if ( $meaning->m_lang() eq 'en' ) {
	            push @{$local->{meanings}}, $meaning->meaning();
	        }
	    }
	    
	    foreach my $count ( $kanji->stroke_counts()->all() ) {
	        push @{$local->{strokes}}, $count->stroke_count();
	    }
	    
	    push @result, $local;
	}
	
	return \@result;
}

sub details : Local {
  my ( $self, $c ) = @_;

  $c->stash->{template} = 'kanji/details.tt';
	$c->stash->{page} = 'kanji';
	
	return unless scalar @{$c->req->args} > 0;
	
	# Get the kanji we are to get details on
	my $unprocessed	= $c->req->arguments->[0];
	
	if ( $c->flavour eq 'j_mobile' ) {
		$unprocessed = decode('shift-jis', $unprocessed);
	}
	else {
		$unprocessed = decode_utf8($unprocessed);
	}
	
	$unprocessed	=~ s/\P{Han}//g;
	$unprocessed	= substr $unprocessed, 0, 20;
	
	return unless $unprocessed;
		
	# Get from DB
	my @kanji = split //, $unprocessed;
	my @result = $c->model('DJDB::Kanji')->search(
		{
			kanji => [@kanji]
		}
	);
	
	# Order like in the URL
	foreach my $kanji (@kanji) {
		foreach my $found (@result) {
			if ($found->kanji eq $kanji) {
				push @{$c->stash->{kanji}}, $found;
			}
		}
	}
	
	$c->req->params->{reading} = join('', map {$_->kanji} @{$c->stash->{kanji}});
	
	# Get the variants and parts
	foreach my $kanji (@{$c->stash->{kanji}}) {
		# Parts
    my @parts = $c->model('DJDB::Kanji')->find({kanji => $kanji->kanji})->radicals;
    push @{$c->stash->{kanji_parts}->{$kanji->id}}, @parts;
		
		# Variants
		foreach my $variant ( @{$kanji->data->{variants}} ) {
			my $variants = $c->model('DJDB::KanjiCodes')->search(
				{
				  section => 'codepoint',
					type => $variant->{var_type},
					value => $variant->{content},
				}
			);
			
			push @{$c->stash->{kanji_variants}->{$kanji->id}}, $variants->first;
		}
	}
	
	if ( $c->flavour eq q{iphone} ) {
	  $c->stash->{json} = {
	    type => 'details',
	    kanji => $self->inflate_details_for_iphone($c),
	  };
    $c->stash(current_view => 'JSON');
	}
}

sub inflate_details_for_iphone {
	my ( $self, $c ) = @_;
	
	my @result;
	
	foreach my $kanji ( @{$c->stash->{kanji}} ) {
	    my $local = {};
	    
	    $local->{literal} = $kanji->literal();
	    $local->{grade} = defined $kanji->grade() ? $kanji->grade() : 0;
	    $local->{id} = $kanji->id();
	    
	    foreach my $reading ( $kanji->readings()->search({},{order_by=>'normalized'})->all() ) {
            push @{$local->{readings}}, {
                reading => $reading->reading(),
                r_type => $reading->r_type(),
                normalized => $reading->normalized(),
            };
	    }
	    
	    foreach my $radical ( $kanji->radicals()->all() ) {
            push @{$local->{radicals}}, {
                rad_type => $radical->rad_type(),
                rad_value => $radical->rad_value(),
                glyph => @{$c->config->{radicals}}[$radical->rad_value()]->{glyph},
            };
	    }
	    
	    foreach my $qc ( $kanji->query_codes()->all() ) {
	        if ( $qc->qc_type() eq 'skip' ) {
	            push @{$local->{skip_codes}}, $qc->q_code();
	        }
	    }
	    
	    foreach my $cp ( $kanji->codepoints()->all() ) {
	        if ( $cp->cp_type() eq 'ucs' ) {
	            push @{$local->{unicodes}}, $cp->cp_value();
	        }
	    }
	    
	    foreach my $part ( @{$c->stash->{kanji_parts}->{$kanji->id}} ) {
	        push @{$local->{parts}}, $part->radical();
	    }
	    
	    foreach my $variant ( @{$c->stash->{kanji_variants}->{$kanji->id}} ) {
	        next if $variant == undef;
	        push @{$local->{variants}}, $variant->kanji()->literal();
	    }
	    
	    foreach my $nanori ( $kanji->nanoris_rs()->search({},{order_by=>'nanori'})->all() ) {
	        push @{$local->{nanoris}}, $nanori->nanori();
	    }
	    
	    foreach my $meaning ( $kanji->meanings_rs()->search({},{order_by=>'meaning'})->all() ) {
	        push @{$local->{'meanings_' . $meaning->m_lang()}}, $meaning->meaning();
	    }
	    
	    foreach my $count ( $kanji->stroke_counts_rs()->search({},{order_by=>'stroke_count'})->all() ) {
	        push @{$local->{strokes}}, $count->stroke_count();
	    }
	    
	    foreach my $freq ( $kanji->frequencies()->all() ) {
	        push @{$local->{frequencies}}, $freq->frequency();
	    }
	    
	    push @result, $local;
	}
	
	return \@result;
}

=back


=head1 AUTHOR

Kim Ahlström

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
