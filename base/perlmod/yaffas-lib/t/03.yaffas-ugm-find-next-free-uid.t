#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Yaffas::Test;
use Yaffas::UGM;

my @testlist = ("root:x:0:0:root:/root:/bin/bash");
is(Yaffas::UGM::get_next_free_uid(\@testlist), 500);

@testlist = ("user:x:500:500:x:/x:/bin/bash");
is(Yaffas::UGM::get_next_free_uid(\@testlist), 501);

@testlist = ("nobody:x:65534:500:x:/x:/bin/bash");
is(Yaffas::UGM::get_next_free_uid(\@testlist), 500);

# real tests on the system
ok(Yaffas::UGM::get_next_free_uid() <= 60000,
	"check that get_next_free_uid() returns something <=60000");
ok(Yaffas::UGM::get_next_free_uid() > 500,
	"check that get_next_free_uid() returns something >500");
