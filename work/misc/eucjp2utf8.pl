#!/usr/bin/perl -w

# eucjp2utf8.pl

# usage: perl eucjp2utf8.pl < infile > outfile

use strict;

use encoding "euc-jp", STDOUT => "utf8";

while(<>){print};