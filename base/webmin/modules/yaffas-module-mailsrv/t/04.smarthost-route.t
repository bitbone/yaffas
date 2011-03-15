#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Mailsrv qw(set_smarthost_routing get_smarthost_routing set_smarthost);

Yaffas::Test::create_file(Yaffas::Constant::FILE->{bbexim_conf});

my ($t, $v);

lives_ok {($t, $v) = get_smarthost_routing()} "Read routing";
check_route($t, $v, 0, undef);

dies_ok {set_smarthost_routing(1, "bitbone.de")} "Set smarthost routing without smarthost";

lives_ok { set_smarthost("192.168.0.1", "erwin", 'myp@ssw0rd') } "Set smarthost";

dies_ok {set_smarthost_routing(1, "-bitbone")} "Set smarthost routing with invalid domain";
dies_ok {set_smarthost_routing(1, "bitbone-")} "Set smarthost routing with invalid domain";
lives_ok {set_smarthost_routing(1, "bitbone.de")} "Set smarthost routing with valid domain";

lives_ok {set_smarthost_routing(1, "bitbone.de")} "Set smarthost routing with valid domain";
lives_ok {($t, $v) = get_smarthost_routing()} "Read routing";
check_route($t, $v, 1, "bitbone.de");

lives_ok {set_smarthost_routing(0, "bitbone.de")} "Remove smarthost routing";
lives_ok {($t, $v) = get_smarthost_routing()} "Read routing";
check_route($t, $v, 0, undef);

sub check_route {
	my $t = shift;
	my $v = shift;

	my $st = shift;
	my $sv = shift;

	is($t, $st, "Type is $st");
	is($v, $sv, "Domain is ".(defined $sv ? $sv : "undef"));
}
