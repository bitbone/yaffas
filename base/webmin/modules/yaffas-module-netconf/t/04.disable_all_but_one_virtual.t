#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Netconf;

my $conf = Yaffas::Module::Netconf->new(1);

my $vdev = $conf->add_virtual_device("eth0");

foreach my $d (values %{$conf->{DEVICES}}) {
	$d->enable(0);
}
dies_ok {$conf->save()} "can't save with only one virtual enabled interface";
is($vdev->enable(), 0, "eth0:0 has to be disabled");
$conf->delete_virtual_device($vdev->{DEVICE});
