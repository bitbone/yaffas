#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;
use Yaffas::File;
use Yaffas::Product;
use Yaffas::Module::ChangePW;

if (Yaffas::Product::check_product("mailgate")) {
	plan tests => 3;
}
else {
	plan skip_all => "mailgate not installed";
}

my $OLDPASSWORD = '$1$KiYk$kTjQn54DkCFfswfkLb8Tk0';

dies_ok {Yaffas::Module::ChangePW::_qreview_pass("test")} "dies because no users file exists";

Yaffas::Test::setup_file("data/users.conf", Yaffas::Constant::FILE->{qreview_users});

lives_ok {Yaffas::Module::ChangePW::_qreview_pass("test")} "set new password to test";

my $f = Yaffas::File->new(Yaffas::Constant::FILE->{qreview_users});
my $password = "";

foreach my $line ($f->get_content()) {
	if ($line =~ /^auth:admin:passwd:(.*)/) {
		$password = $1;
	}
}

isnt ($password, $OLDPASSWORD, "check if password was set");
