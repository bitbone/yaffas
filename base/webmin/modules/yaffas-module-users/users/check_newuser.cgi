#!/usr/bin/perl
# check_modpassuser.cgi
# sets new pass for ldap user
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Error qw(:try);
use Yaffas::UI qw(yn_confirm);
use Yaffas::UGM qw(is_user_in_group get_system_users);
use Yaffas::Module::Users;
use Yaffas::Module::Mailalias;
use Yaffas::Module::Mailsrv;
use Yaffas::Check;
use Yaffas::Exception;
use Yaffas::Constant;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Yaffas;
#use Yaffas::Mail;

require "./forms.pl";
our $cgi = $Yaffas::UI::Cgi;


Yaffas::init_webmin();
header($main::text{'check_modpassuser_header'}, "");
ReadParse();

my $user = $main::in{login_};
my $pass1 = $main::in{userpass_};
my $pass2 = $main::in{userpass2_};
my $email = $main::in{email_};
my $givenname = $main::in{givenname_};
my $surname = $main::in{surname_};
my $filetype = $main::in{filetype_};
my $group = $main::in{group_};
my $sendas = $main::in{sendas_};
my $delalias = $main::in{'delalias'};
my $zarafaquota = $main::in{zarafaquota_};
my $zarafaadmin = $main::in{zarafaadmin_};
my $zarafashared = $main::in{zarafashared_};
my @sendas = split /\0/, ($sendas || "");
my @groups = split /\0/, ($group || "");
my @aliases = split /\s*,\s*/, ($main::in{alias_} || "");
my @never_users = @{ Yaffas::Constant::MISC->{"never_users"} };
my $businessphone = $main::in{businessphone_};
my $location = $main::in{location_};
my $faxnumber = $main::in{faxnumber_};
my $department = $main::in{department_};
push @never_users, get_system_users();

try {
	my $e = Yaffas::Exception->new();

	$e->add('err_no_local_auth') unless ( Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP or
					      Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::FILES );
	$e->throw if $e;

	Yaffas::Check::username($user) or $e->add("err_username");
	Yaffas::Check::password($pass1) or $e->add("err_password");

	if(grep { $user eq $_ } @never_users)
	{
		$e->add('err_never_user');
	}

	for (@groups) {
		Yaffas::Check::groupname($_) or $e->add("err_groups", $_);
	}

	for (@aliases) {
		Yaffas::Check::alias($_) or $e->add("err_alias_name", $_);
	}
	$pass1 eq $pass2 or $e->add("err_password_equal");
	#create warning if necessary
	my $warn_string = "";
	try {
		Yaffas::Module::Users::check_reasonable_mail($user,\$email,@aliases);
	} catch Yaffas::Exception with {
		my @err;
		my $exception = shift;
		my %errors = %{$exception->get_errors()};
		foreach my $key (keys %errors) {
			my $string = "";
			if (defined($main::text{$key})) {
				$string = "$main::text{$key}";
			} else {
				$string = "$key";
				$string .= " - ".$exception->text() if (defined($exception->text()));
			}
			my @errors = @{$errors{$key}};
			$string .= " " . $Cgi->ul(
						  $Cgi->li([
							   @errors
							   ]),
						 )   if( @errors >= 1 && $errors[0] ne "");
			push @err, $string;
		}
		$warn_string = "$main::text{lbl_user_create_warning}:". $Cgi->br() . $Cgi->ol($Cgi->li([@err]));
	};

	if ($e) {
		$e->throw();
	}

	if (defined $delalias) {
		# Delete an existing alias with the same name.
		my $alias = Yaffas::Mail::Mailalias->new();
		$alias->remove($user);
		$alias->write();
	}
	
	Yaffas::UGM::add_user($user, $email, $givenname, $surname, @groups);

	try {
		Yaffas::UGM::password($user, $pass1);

		## filetype
		if (defined($filetype)) {
			Yaffas::UGM::mod_user_ftype({$user=>$filetype});
		}

		if (@aliases) {
			my $a = Yaffas::Module::Mailalias->new();
			foreach my $alias (@aliases) {
				$a->add($alias, $user);
			}
			$a->write();
		}

		if (Yaffas::Product::check_product("zarafa") || Yaffas::Auth::is_auth_srv()) {
			Yaffas::Mail::set_zarafa_quota($user, $zarafaquota);
			Yaffas::Module::Users::set_zarafa_admin($user, $zarafaadmin);
			Yaffas::Module::Users::set_zarafa_shared($user, $zarafashared);
		}

        Yaffas::UGM::set_additional_values($user, {
                $Yaffas::Module::Users::ADDITIONAL_VALUES->{businessphone} => $businessphone,
                $Yaffas::Module::Users::ADDITIONAL_VALUES->{location} => $location,
                $Yaffas::Module::Users::ADDITIONAL_VALUES->{faxnumber} => $faxnumber,
                $Yaffas::Module::Users::ADDITIONAL_VALUES->{department} => $department,
            }
        );

        Yaffas::UGM::set_send_as($user, [@sendas]);
	} catch Yaffas::Exception with {
		my $e = shift;
		Yaffas::UGM::rm_user($user);
		throw $e;
	};

	if (Yaffas::Product::check_product("zarafa")) {
		Yaffas::Module::Users::check_zarafa_store($user);
	}

	print ($warn_string eq "" ? Yaffas::UI::ok_box() : Yaffas::UI::ok_box($warn_string));
} catch Yaffas::Exception with {
	my $e = shift;
	print Yaffas::UI::all_error_box($e);
} otherwise {
	print Yaffas::UI::error_box(shift);
};

footer();
=pod

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
