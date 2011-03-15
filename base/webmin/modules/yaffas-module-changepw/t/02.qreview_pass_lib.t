#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;
use Yaffas::Module::ChangePW;

if (Yaffas::Product::check_product("mailgate")) {
	plan tests => 1;
}
else {
	plan skip_all => "mailgate not installed";
}

`cp -a /usr/local/mppserver/lib /tmp/`;

dies_ok {Yaffas::Module::ChangePW::_qreview_pass("test")} "dies because lib couldn't be loaded";

`mv /tmp/lib /usr/local/mppserver/`;
