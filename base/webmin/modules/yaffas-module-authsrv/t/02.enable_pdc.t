#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::AuthSrv;
use Yaffas::File;

Yaffas::Test::create_file( Yaffas::Constant::FILE->{smb_includes} );

lives_ok {Yaffas::Module::AuthSrv::auth_srv_pdc("activate")} "enable pdc";
is(Yaffas::Module::AuthSrv::auth_srv_pdc(), 1, "check if it is enabled");
lives_ok {Yaffas::Module::AuthSrv::auth_srv_pdc("activate")} "enable pdc it again";
is(Yaffas::Module::AuthSrv::auth_srv_pdc(), 1, "check if it is still enabled");

my @content = Yaffas::File->new(Yaffas::Constant::FILE->{smb_includes})->get_content();
is (scalar @content, 3, "check if file has two lines");
