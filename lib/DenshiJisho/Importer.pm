package DenshiJisho::Importer;

use FindBin qw($Bin);
use Path::Class;
use YAML 'LoadFile';
use Exporter 'import';
use DenshiJisho::Schema::DJDB;
use Data::Dumper;
our @EXPORT = qw( $djdb_schema insert );

my $config = LoadFile(file($Bin, '..', '..', 'denshijisho_local.yml')); 
my $dsn    = $config->{'Model::DJDB'}->{connect_info}->[0]; 
my $HOME   = dir($Bin, '..'); 
$dsn       =~ s/__HOME__/$HOME/;

our $djdb_schema = 
  DenshiJisho::Schema::DJDB->connect($dsn, $config->{'Model::DJDB'}->{connect_info}->[1], $config->{'Model::DJDB'}->{connect_info}->[2]) 
  or die "Failed to connect to database at $dsn";

sub insert {
  my ($sql, @args) = @_;

  my $i = 0;
  $sql =~ s{\?}{
    $djdb_schema->storage->dbh->quote($args[$i++]);
  }egx;

  $djdb_schema->storage->dbh->do($sql);
}

1;