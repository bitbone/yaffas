#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Check;

my @truegroups = ("bkusers","Domain Admins","Print Operators","blabla");
my @falsegroups =("123","Domänenadministratoren","Domaenen Administratoren","");
foreach my $group (@truegroups) {
	is(1,Yaffas::Check::groupname($group),"test true group: '$group'");
}
foreach my $group (@falsegroups) {
	is(0,Yaffas::Check::groupname($group),"test false group: '$group'");
}
