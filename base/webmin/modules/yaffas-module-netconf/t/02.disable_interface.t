#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Netconf;

my $conf = Yaffas::Module::Netconf->new(1);

my $eth0 = $conf->device("eth0");

my $eth00;
lives_ok {$eth00 = $conf->add_virtual_device("eth0")} "add first virtual device";
my $eth01;
lives_ok {$eth01 = $conf->add_virtual_device("eth0")} "add second virtual device";

$eth0->enable(0);
$conf->disable_virtual();

is($eth00->enabled(), 0, "check if first virtual is disabled");
is($eth01->enabled(), 0, "check if second virtual is disabled");
lives_ok {$conf->delete_virtual_device($eth00->{DEVICE})} "remove first device";
lives_ok {$conf->delete_virtual_device($eth01->{DEVICE})} "remove second device";
