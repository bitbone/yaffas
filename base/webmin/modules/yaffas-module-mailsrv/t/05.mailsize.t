#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Mailsrv qw(set_mailsize get_mailsize);

Yaffas::Test::create_file(Yaffas::Constant::FILE()->{bbexim_conf});

my $v;
lives_ok {$v = get_mailsize()} "Get mailsize";
is($v, undef, "Is mailsize == undef");

dies_ok {set_mailsize("a")} "Set an invalid value";
dies_ok {set_mailsize('$')} "Set an invalid value";
dies_ok {set_mailsize("-1")} "Set an invalid value";
dies_ok {set_mailsize(0)} "Set an invalid value";
dies_ok {set_mailsize(undef)} "Set an invalid value";

lives_ok {set_mailsize(10)} "Sets mailsize to 10 MB";

lives_ok {$v = get_mailsize()} "Get mailsize";
is($v, 10, "Is mailsize == 10");

Yaffas::Test::setup_file("bbexim.conf-mailadmin", Yaffas::Constant::FILE()->{bbexim_conf});

lives_ok {$v = get_mailsize()} "Get mailsize";
is($v, 100, "Is mailsize == 100");

