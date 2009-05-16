#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use DenshiJisho::Schema::DJDB;
use DenshiJisho::Importer qw($djdb_schema);

$djdb_schema->create_ddl_dir(
   ['MySQL', 'SQLite'],
);
# $schema->deploy({
#     add_drop_table => 1,
# });   
