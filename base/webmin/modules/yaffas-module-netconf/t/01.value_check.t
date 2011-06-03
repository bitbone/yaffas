#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Netconf;

my $conf = Yaffas::Module::Netconf->new(1);
my $eth0 = $conf->device("eth0");

dies_ok {$eth0->set_ip("192.168.7.11", "234.30.0.4")} "wrong netmask";
dies_ok {$eth0->set_ip("192.168.7.255", "255.255.255.0")} "wrong ip";
dies_ok {$eth0->set_ip("192.168.7.256", "255.255.255.0")} "wrong ip";
dies_ok {$eth0->set_ip("192.168.7.056", "255.255.255.0")} "wrong ip";
dies_ok {$eth0->set_ip("192.168.7.256")} "no netmask";
dies_ok {$eth0->set_ip()} "no values";
lives_ok {$eth0->set_ip("192.168.0.11", "255.255.255.0")} "ip ok";
is ($eth0->get_ip(), "192.168.0.11", "read ip");
lives_ok {$eth0->set_ip("192.168.7.11", "255.255.255.0")} "ip ok";

dies_ok {$eth0->set_gateway()} "no gateway";
lives_ok {$eth0->set_gateway("192.168.7.254")} "gateway ok";

dies_ok {$eth0->set_dns("192.168.7.256")} "wrong dns";
dies_ok {$eth0->set_dns()} "wrong dns";
lives_ok {$eth0->set_gateway("")} "remote gateway";
lives_ok {$eth0->set_gateway("192.168.7.254")} "reset gateway";
lives_ok {$eth0->set_dns("192.168.7.250")} "dns ok";
lives_ok {$eth0->set_dns(["192.168.7.250", "192.168.7.251"])} "multiple dns ok";

dies_ok {$eth0->set_search()} "no search domain";
lives_ok {$eth0->set_search("")} "remove search domain";
dies_ok {$eth0->set_search("bla§")} "wrong search domain";
dies_ok {$eth0->set_search(["bla.bitbone.de", "blub\$.bitbone.de"])} "wrong search domain";
lives_ok {$eth0->set_search("technik.bitbone.de")} "search ok";
lives_ok {$eth0->set_search(["technik.bitbone.de", "yaffas.org"])} "multiple search ok";

dies_ok {$conf->hostname("")} "empty hostname";
dies_ok {$conf->hostname("ho\$tname")} "wrong hostname";
lives_ok {$conf->hostname("hostname")} "hostname ok";
is ($conf->hostname(), "hostname", "read hostname");

dies_ok {$conf->domainname("")} "empty domainname";
dies_ok {$conf->domainname("doma\$nname")} "wrong domainname";
lives_ok {$conf->domainname("domainname.de")} "domainname ok";
is ($conf->domainname(), "domainname.de", "read domainname");

dies_ok {$conf->workgroup("")} "empty workgroup";
dies_ok {$conf->workgroup("doma\$nname")} "wrong workgroup";
lives_ok {$conf->workgroup("workgroup.de")} "workgroup ok";
is ($conf->workgroup(), "workgroup.de", "read workgroup");

is ($eth0->get_ip(), "192.168.7.11", "read ip");
is ($eth0->get_gateway(), "192.168.7.254", "read gateway");
eq_array ($eth0->get_dns(), ["192.168.7.250", "192.168.7.251"], "read dns");
eq_array ($eth0->get_search(), ["technik.bitbone.de", "yaffas.org"], "read search");
