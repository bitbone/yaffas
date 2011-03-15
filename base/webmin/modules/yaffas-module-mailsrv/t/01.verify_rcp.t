#!/usr/bin/perl

use strict;
use warnings;

use Yaffas::Module::Mailsrv qw(get_verify_rcp set_verify_rcp);
use Yaffas::Constant;

use Test::More tests => 15;
use Test::Exception;
use Yaffas::Test;

Yaffas::Test::create_file(Yaffas::Constant::FILE()->{bbexim_conf});

#check normal function
is_deeply([get_verify_rcp()],["delete",undef ], "default setting 'delete'");
lives_ok {set_verify_rcp('mailadmin','erwin@localhost')} "Setting erwin\@localhost as mailadmin";
is_deeply([get_verify_rcp()], ['mailadmin','erwin@localhost'], "Check if set was correct");
lives_ok {set_verify_rcp('refuse')} "setting refuse as verify action";
is_deeply([get_verify_rcp()],["refuse",undef ], "Check if refuse was set correctly");
dies_ok {set_verify_rcp('mailadmin','erwinlocalhost')} "Setting erwinlocalhost as mailadmin";
is_deeply([get_verify_rcp()],["refuse",undef ], "Check if refuse is still set correctly");

#check with action + mailadmin
lives_ok {set_verify_rcp('refuse','erwin@localhost')} "Setting 'refuse' and erwin\@localhost as mailadmin";
is_deeply([get_verify_rcp()],["refuse",undef ], "Check if refuse is still set correctly");
lives_ok {set_verify_rcp('delete','erwin@localhost')} "Setting 'delete' and erwin\@localhost as mailadmin";
is_deeply([get_verify_rcp()],["delete",undef ], "Check if  'delete' is still set correctly");

#check with files
Yaffas::Test::setup_file("bbexim.conf-mailadmin", Yaffas::Constant::FILE()->{bbexim_conf});
is_deeply([get_verify_rcp()], ['mailadmin','albert@bitbone.de'], "Mailadmin from file is albert\@bitbone.de");
Yaffas::Test::setup_file("bbexim.conf-refuse", Yaffas::Constant::FILE()->{bbexim_conf});
is_deeply([get_verify_rcp()],["refuse",undef ], "Check if refuse is set from file");
dies_ok{set_verify_rcp('abc')} "setting 'abc' as verify action";
is_deeply([get_verify_rcp()],["refuse",undef ], "Check if refuse is still set");
