#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas;

dies_ok(sub {Yaffas::do_back_quote()}, "no parameter");
dies_ok(sub {Yaffas::do_back_quote("/tmp/foo-bar-file")}, "execute unknown file");
lives_ok(sub {Yaffas::do_back_quote("/bin/echo")}, "can run /bin/echo");
