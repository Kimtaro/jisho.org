use warnings;
use strict;
use Smart::Comments;
use lib(qw/lib/);                                                                                                                                                              
use DenshiJisho::Schema::DJDB;                                                                                                                                                 
select STDOUT; $| = 1; # Make unbuffered

my $s = DenshiJisho::Schema::DJDB->connect('DBI:mysql:database=jisho3', 'jisho', '');                                                                                    

# Attatches a word_id to representations that lack it

my $is_null = 'IS NULL';
foreach my $r( $s->resultset('Representations')->search(word_id => \$is_null)->all ) { ### Working===[%]     done
    $r->word_id($r->reading->word_id);                                                                                                                                            
    $r->update;                                                                                                                                                                    
}