#!/usr/bin/perl

use strict;
use warnings;

use lib '/opt/yaffas/lib/perl5';

use Yaffas;
use Yaffas::Module::Setup;
use Yaffas::Module::ZarafaConf;
use Yaffas::Module::ChangePW;
use Yaffas::Module::AuthSrv;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN POSTFIX WEBMIN);
use Yaffas::UGM;
use Yaffas::File;
use Yaffas::Constant;


my $password = "yaffas";

my $mysql_host = "localhost";
my $mysql_database = "zarafa";
my $mysql_user = "root";
my $mysql_password = "";

Yaffas::Module::ChangePW::change_admin_password($password);
Yaffas::Module::ZarafaConf::set_zarafa_database($mysql_host, $mysql_database, $mysql_user, $mysql_password);
Yaffas::Module::Setup::hide();

try
{
    Yaffas::Service::control(NSCD, STOP);
    Yaffas::Service::control(GOGGLETYKE, STOP);
    if(Yaffas::Service::control(WINBIND, START)) {
        # sleeping some time, so winbind can get all users
        sleep 7;
    }

    Yaffas::Module::AuthSrv::set_local_auth();

    Yaffas::Module::AuthSrv::mod_nsswitch();

    Yaffas::Service::control(SAMBA, RESTART);
    Yaffas::Service::control(NSCD, START);
    Yaffas::Service::control(GOGGLETYKE, START);
    Yaffas::Service::control(SAMBA, RESTART);
    Yaffas::Service::control(ZARAFA_SERVER, RESTART) if Yaffas::Product::check_product("zarafa");
    system(Yaffas::Constant::APPLICATION->{zarafa_admin}, "-s");
    Yaffas::Service::control(USERMIN, RESTART);
    Yaffas::Service::control(POSTFIX, RESTART);
    Yaffas::File->new(Yaffas::Constant::FILE->{auth_wizard_lock}, 1)->save();

    # fork, because we have to restart webmin
    my $pid = fork;
    if ($pid == 0) {
        # child
        try {
            Yaffas::Service::control(WEBMIN, RESTART);
        } catch Yaffas::Exception with {
            print Yaffas::UI::all_error_box(shift);
        };
    } else {
        # parent
        wait;
    }
}
catch Yaffas::Exception with
{
    Yaffas::Service::control(NSCD, START);
    Yaffas::Service::control(GOGGLETYKE, START);
    print Yaffas::UI::all_error_box(shift);
};

