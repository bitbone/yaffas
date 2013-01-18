#!/usr/bin/perl -w

package Yaffas::Module::ChangeLang;

our @ISA = ("Yaffas::Module");

use strict;
use warnings;

use Error qw(:try);
use Yaffas::File::Config;
use Yaffas::Constant;
use Yaffas::Exception;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Product;
use Yaffas::Service qw(control BBLCD STATUS RESTART);

=head1 NAME

Yaffas::Module::ChangeLang

=head1 DESCRIPTION

Module for setting and getting language settings

=head1 FUNCTIONS

=over

=item get_lang( [USER] )

Returns language setting for USER. If USER is omitted then language for webmin is set.

=cut

sub get_lang(;$) {
	my $user = shift;

	my $lang = (defined($user) ? "lang_$user" : "lang");

	my $filename = (defined($user) ? Yaffas::Constant::FILE->{usermin_config} : Yaffas::Constant::FILE->{webmin_config});

	my %langs = get_all_lang($filename);

	if ($langs{$lang}) {
		return $langs{$lang};
	} elsif (defined($langs{"lang"})) {
		return $langs{lang};
	}
	return "en";
}

sub get_all_lang($) {
	my $filename = shift;

	my $file = Yaffas::File::Config->new($filename, {-SplitPolicy=>"equalsign"}) or return 0;

	return $file->get_cfg()->getall();

	#my @lines = $file->search_line(qr/$lang=.*/);
}

=item set_lang ( LANG, [USER] )

Sets the language. If USER is ommited than the language for webmin is set.

=cut

sub set_lang($;$) {
	my $lang = shift;
	my $user = shift;

	if ($lang ne "de" && $lang ne "en" && $lang ne "nl" && $lang ne "fr" && $lang ne "pt_BR") {
		throw Yaffas::Exception("err_lang");
	}

	my $conf_section = "";
	my @filename = ();

	if (defined($user)) {
		$conf_section = "lang_$user";
		push @filename, Yaffas::Constant::FILE->{usermin_config};
	} else {
		$conf_section = "lang";
		push @filename, Yaffas::Constant::FILE->{usermin_config}, Yaffas::Constant::FILE->{webmin_config};
	}

	foreach my $filename (@filename) {
		if (-r $filename) {
			my $file = Yaffas::File->new($filename) or throw Yaffas::Exception("err_file_read", $filename);

			my @lines = $file->search_line(qr/$conf_section=.*/);

			if (defined($lines[0])) {
				$file->splice_line($_, 1, "$conf_section=$lang") foreach(@lines);
			} else {
				$file->add_line("$conf_section=$lang");
			}

			$file->save() or throw Yaffas::Exception("err_file_write", $filename);
		}
	}

	if ($conf_section eq "lang" && Yaffas::Product::check_product("zarafa")) {
		my $file = Yaffas::File->new("/etc/zarafa/userscripts/createuser.d/00createstore");
		if (defined ($file)) {
			my @content = $file->get_content();
			my $lineno = $file->search_line(qr/^zarafa-admin.*--create-store/);

			my $langstr = "en_US.UTF-8";

			if ($lang eq "de") {
				$langstr = "de_DE.UTF-8"
			}
			if ($lang eq "fr") {
				$langstr = "fr_FR.UTF-8"
			}
			if ($lang eq "nl") {
				$langstr = "nl_NL.UTF-8"
			}
			if ($lang eq "pt_BR") {
				$langstr = "pt_BR.UTF-8"
			}

			if ($lineno > 0) {
				my $line = $content[$lineno];
				my $newline;

				if ($line =~ /^(.*)(--lang\s+\S+)(.*)$/) {
					$newline =  $1."--lang $langstr".$3;
				}
				else {
					$newline =  $line." --lang $langstr";
				}

				$file->splice_line($lineno, 1, $newline);
				$file->save();
			}

			if (Yaffas::Constant::OS eq "Ubuntu" or Yaffas::Constant::OS eq 'Debian') {
				system(Yaffas::Constant::APPLICATION->{'locale-gen'}, $langstr);
			}
		}
	}
	#apply new language to LCD
	_restart_display_clients();
	return 1;
}

sub _set_lang_config($;$) {
	my $lang = shift;
	my $user = shift;

	my $conf = Yaffas::Conf->new();
	my $section;
	my $function;
	if (defined($user)) {
		$section = $conf->section("changelang-usermin");
		$function = Yaffas::Conf::Function->new($user, "Yaffas::Module::ChangeLang::set_lang");
		$function->add_param({type=>"scalar", param=>$lang});
		$function->add_param({type=>"scalar", param=>$user});
		$section->del_func($user);
		$section->add_func($function);
	} else {
		$section = $conf->section("changelang-webmin");
		$function = Yaffas::Conf::Function->new("admin", "Yaffas::Module::ChangeLang::set_lang");
		$function->add_param({type=>"scalar", param=>$lang});
		$section->del_func("admin");
		$section->add_func($function);
	}
	$conf->save();
}

sub conf_dump() {
	my %hash = get_all_lang(Yaffas::Constant::FILE->{usermin_config});
	%hash = (%hash, get_all_lang(Yaffas::Constant::FILE->{webmin_config}));

	foreach my $key (keys %hash) {
		if ($key =~ /^lang_{0,1}(.*)$/) {
			if ($1 ne "") {
				_set_lang_config($hash{$key}, $1);
			} else {
				_set_lang_config($hash{$key});
			}
		}
	}
}

sub _restart_display_clients() {
	if (control(BBLCD(),STATUS())) {
		control(BBLCD(),RESTART())
	}
}

=back

=cut

1;
=head1 COPYRIGHT

This file is part of yaffas.

yaffas is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

yaffas is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
License for more details.

You should have received a copy of the GNU Affero General Public
License along with yaffas.  If not, see
<http://www.gnu.org/licenses/>.
