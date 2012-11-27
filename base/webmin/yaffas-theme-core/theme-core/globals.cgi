#!/usr/bin/perl

use Yaffas;
use Yaffas::UGM;
use Yaffas::Auth;
use Yaffas::UI::Webmin;
use Yaffas::File::Config;
use Yaffas::Product;
use Yaffas::Module::ChangeLang;
use File::Find;
use JSON;

print "Content-type: application/javascript;charset=utf8\n\n";

Yaffas::init_webmin();

my %lang;

my $l = Yaffas::UI::Webmin::get_lang_name();

my $lg = Yaffas::File::Config->new("/opt/yaffas/webmin/lang/$l", {-SplitPolicy => 'equalsign'});
$lang{global} = {$lg->get_cfg->getall()};

my %modules = ();

sub wanted() {
	if ($File::Find::name =~ m#/opt/yaffas/(webmin|usermin)/([^/]+)/#) {
		$modules{$2} = 1;
	}
	if ($File::Find::name =~ m#/opt/yaffas/(webmin|usermin)/(.*)/lang/$l#) {
		my $lg = Yaffas::File::Config->new($File::Find::name, {-SplitPolicy => 'equalsign'});
		$lang{$2} = {$lg->get_cfg->getall()};
	}
}


find({ wanted => \&wanted, follow => 1, follow_skip => 2 }, qw(/opt/yaffas/webmin/ /opt/yaffas/usermin/));

$lang{used} = Yaffas::UI::Webmin::get_lang_name();

print "Yaffas.LANG = ".to_json(\%lang, {latin1 => 1}).";";
print "Yaffas.PRODUCTS = ".to_json([Yaffas::Product::get_all_installed_products()], {latin1 => 1}).";";
print "Yaffas.AUTH = ".to_json({"current" => Yaffas::Auth::get_auth_type()}, {latin1 => 1}).";";
print "Yaffas.CONFIG = ".to_json({"theme" => Yaffas::UI::Webmin::get_theme()}, {latin1 => 1}).";";
my @modules = keys %modules;
print "Yaffas.MODULES = ".to_json(\@modules).";";
