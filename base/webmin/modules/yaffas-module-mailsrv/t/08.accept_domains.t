#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Mailsrv;

Yaffas::Test::create_dir("/etc/exim4/");

# add
is(Yaffas::Module::Mailsrv::set_accept_domains(undef), undef, "undef domain");
is(Yaffas::Module::Mailsrv::set_accept_domains('bit$§§'), undef, "invalid domain");

lives_ok {Yaffas::Module::Mailsrv::set_accept_domains('bitbone.de')} "valid domain bitbone.de";
lives_ok {Yaffas::Module::Mailsrv::set_accept_domains('bitbone.de')} "valid domain bitbone.de which exists";

# remove
is(Yaffas::Module::Mailsrv::rm_accept_domains(undef), undef, "undef domain");
lives_ok {Yaffas::Module::Mailsrv::rm_accept_domains("bitbone.de")} "remove existing domain bitbone.de";
lives_ok {Yaffas::Module::Mailsrv::rm_accept_domains("bitbone.com")} "remove not existing domain bitbone.com";
