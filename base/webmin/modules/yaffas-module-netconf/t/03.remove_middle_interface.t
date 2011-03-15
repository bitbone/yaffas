#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Netconf;

my $conf = Yaffas::Module::Netconf->new(1);

my $eth0 = $conf->device("eth0");
my $name;
lives_ok {$name = $conf->add_virtual_device("eth0")->{DEVICE}} "read device name";
$conf->add_virtual_device("eth0");

$conf->delete_virtual_device($name);

is($conf->add_virtual_device("eth0")->{DEVICE}, $name, "check if new name eq old name");
