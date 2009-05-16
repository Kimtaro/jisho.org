#!/usr/bin/perl -w

BEGIN { push @INC, "../lib" }

use strict;
use Lingua::JA::Verb;

my @pos = Lingua::JA::Verb->inflected_to_plain("はしった");
print "$_\n" foreach @pos;

my @pos = Lingua::JA::Verb->inflected_to_plain("走った");
print "$_\n" foreach @pos;