#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Mailsrv qw(set_smarthost get_smarthost rm_smarthost);

Yaffas::Test::create_file(Yaffas::Constant::FILE->{bbexim_conf});
Yaffas::Test::create_file(Yaffas::Constant::FILE->{exim_passwd_client});

my ($s, $u, $p);

lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost";
check_smarthost($s, $u, $p, undef, "", "");

lives_ok { set_smarthost("192.168.0.1", "erwin", 'myp@ssw0rd') } "Set smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost again";
check_smarthost($s, $u, $p, "192.168.0.1", "erwin", 'myp@ssw0rd');

dies_ok { set_smarthost('1$2%', "erwin", 'myp@ssw0rd') } "Set smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost again";
check_smarthost($s, $u, $p, "192.168.0.1", "erwin", 'myp@ssw0rd');

dies_ok { set_smarthost('name', "erwin\n", 'myp@ssw0rd') } "Set smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost again";
check_smarthost($s, $u, $p, "192.168.0.1", "erwin", 'myp@ssw0rd');

lives_ok { set_smarthost("192.168.0.1", "", "") } "Set smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost again";
check_smarthost($s, $u, $p, "192.168.0.1", "", "");

lives_ok { set_smarthost("name.bitbone.de", "", "") } "Set smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost again";
check_smarthost($s, $u, $p, "name.bitbone.de", "", "");

dies_ok { set_smarthost("name.bitbone.de", ("a" x 1025), "password") } "Set smarthost with long username";
dies_ok { set_smarthost("name.bitbone.de", "user:name", "password") } "Set smarthost with a : in username";
dies_ok { set_smarthost("name.bitbone.de", "username", "user:name") } "Set smarthost with a : in password";

lives_ok { rm_smarthost("name.bitbone.de") } "Remove Smarthost";
lives_ok { ($s, $u, $p) = get_smarthost() } "Read smarthost";
check_smarthost($s, $u, $p, undef, "", "");

sub check_smarthost {
	my $s = shift;
	my $u = shift;
	my $p = shift;

	my $ss = shift;
	my $su = shift;
	my $sp = shift;

	is($s, $ss, "Smarthost is ".(defined $ss ? $ss : "undef"));
	is($u, $su, "Username is $su");
	is($p, $sp, "Password is $sp");
}
