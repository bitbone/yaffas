#!/usr/bin/perl
# index.cgi
use strict;
use warnings;
use Yaffas;
use Yaffas::UGM;
use Yaffas::UI;
use Yaffas::Exception;
use File::Samba;
use Yaffas::Constant;
use Yaffas::Module::Mailalias;
use Yaffas::Module::Users;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Error qw(:try);

require './forms.pl';

Yaffas::init_webmin();
header($main::text{'index_header'}, "");
ReadParse();

my %info;
for (keys %main::in) {
	if (/^login_(\d+)/) {
		my $uid = $1;
		$info{$uid} = {
					 login => $main::in{'login_' . $uid},
					 pass1 => $main::in{'userpass_' . $uid},
					 pass2 => $main::in{'userpass2_' . $uid},
					 email => $main::in{'email_' . $uid},
					 givenname => $main::in{'givenname_' . $uid},
					 surname => $main::in{'surname_' . $uid},
					 mailgroup => $main::in{'mailgroup_' . $uid},
					 filetype => $main::in{'filetype_' . $uid},
					 group => [ split(/\0/, $main::in{'group_' . $uid}) ],
					 sendas_user => [ split(/\0/, $main::in{'sendas_user_' . $uid}) ],
					 sendas_group => [ split(/\0/, $main::in{'sendas_group_' . $uid}) ],
					 aliases => [ split /\s*,\s*/, $main::in{'alias_'.$uid} ],
					 zarafaquota => $main::in{'zarafaquota_'.$uid},
					 zarafaadmin => $main::in{'zarafaadmin_'.$uid},
					 zarafashared => $main::in{'zarafashared_'.$uid},
					 zarafaimap => $main::in{'zarafaimap_'.$uid},
					 zarafapop3 => $main::in{'zarafapop3_'.$uid},
					 businessphone => $main::in{'businessphone_'.$uid},
					 location => $main::in{'location_'.$uid},
					 department => $main::in{'department_'.$uid},
					 faxnumber => $main::in{'faxnumber_'.$uid},
					};
	}
}

try {
	my @err = ();
	my @ok = ();

	Yaffas::Exception->throw("err_no_local_auth") unless ( Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP or
							       Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::FILES );

	for (keys %info) {
		my $e = Yaffas::Exception->new();

		my $login;

		$login = Yaffas::UGM::get_username_by_uid($_);

		if ($login ne $info{$_}->{login}) {
			try {
				Yaffas::UGM::rename_login($login, $info{$_}->{login});
			} catch Yaffas::Exception with {
				$e->append(shift);
			};

			$login = Yaffas::UGM::get_username_by_uid($_);
		}

		try {

			# wenn password ausgef�llt ist, so hat es sicht geaendert.
			if ($info{$_}->{pass1}) {
				$info{$_}->{pass1} eq $info{$_}->{pass2} or throw Yaffas::Exception("err_password_equal");
				Yaffas::UGM::password($login, $info{$_}->{pass1});
			}
		} catch Yaffas::Exception with {
			$e->append(shift);
		};

		try {

			# name schreiben
			Yaffas::UGM::name($login, $info{$_}->{givenname}, $info{$_}->{surname});
		} catch Yaffas::Exception with {
			$e->append(shift);
		};

		try {
			# gruppe schreiben
			my @groups = @{ $info{$_}->{group} };
			Yaffas::UGM::set_suppl_groups( $login, @groups );
		} catch Yaffas::Exception with {
			$e->append(shift);
		};
		
		try {
			my $email = $info{$_}->{email};
			Yaffas::UGM::set_email($login, $email) if (defined($email));
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};

		try {
			my $businessphone = $info{$_}->{businessphone};
			my $location = $info{$_}->{location};
			my $faxnumber = $info{$_}->{faxnumber};
			my $department = $info{$_}->{department};

            Yaffas::UGM::set_additional_values($login, {
                    $Yaffas::Module::Users::ADDITIONAL_VALUES->{businessphone} => $businessphone,
                    $Yaffas::Module::Users::ADDITIONAL_VALUES->{location} => $location,
                    $Yaffas::Module::Users::ADDITIONAL_VALUES->{faxnumber} => $faxnumber,
                    $Yaffas::Module::Users::ADDITIONAL_VALUES->{department} => $department,
                }
            );
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		
		try {
			if (defined($info{$_}->{filetype})) {
				Yaffas::UGM::mod_user_ftype({$login=>$info{$_}->{filetype}});
			}
		} catch Yaffas::Exception with {
		};

		if (defined($info{$_}->{aliases})) {
			my $bke = Yaffas::Exception->new();
			
			foreach my $alias (@{$info{$_}->{aliases}}) {
				$bke->add("err_alias_name", $alias) unless Yaffas::Check::alias($alias);
			}

			if ($bke) {
				$e->append($bke);
			} else {
				my $a = Yaffas::Module::Mailalias->new();
				# remove old aliases
				my @setaliases = $a->get_user_aliases($login);
				foreach my $alias (@setaliases) {
					$a->remove($alias, $login);
				}

				# set new
				foreach my $alias (@{$info{$_}->{aliases}}) {
					try {
						$a->add($alias, $login);
					} catch Yaffas::Exception with {
						$e->append(shift);
					};
				}
				$a->write();
			}
		}

            try {
                Yaffas::UGM::set_send_as($login, $info{$_}->{sendas_user}, $info{$_}->{sendas_group});
            } catch Yaffas::Exception with {
                $e->append(shift);
            };

		if (Yaffas::Product::check_product("zarafa") || Yaffas::Auth::is_auth_srv()) {
			try {
				Yaffas::Mail::set_zarafa_quota($login, $info{$_}->{zarafaquota});
				Yaffas::Module::Users::set_zarafa_admin($login, $info{$_}->{zarafaadmin});
				Yaffas::Module::Users::set_zarafa_shared($login, $info{$_}->{zarafashared});
				Yaffas::Module::Users::set_features($login, { imap => $info{$_}->{zarafaimap}, pop3 => $info{$_}->{zarafapop3} });
			} catch Yaffas::Exception with {
				$e->append(shift);
			};
		}
		if  ($e) {
			push @err, [$_ , $e ];
		} else {
			push @ok, $login;
		}
	} ## end for keys %info

	if (@ok){
		$Yaffas::UI::Convert_nl = 0;
		print Yaffas::UI::ok_box(
								 $main::text{lbl_changeduser}.":".
								 $Cgi->ul(
										  $Cgi->li([@ok])
										 )
								);
	}

	if (@err) {
		my @existing_groups = get_groups();
		my @mail = Yaffas::UGM::get_users();
		my $size;
		$size = $#existing_groups;
		$size = 2 if $size < 2;
		$size = 5 if $size >= 4;

		print $Cgi->start_form("post", "check_edituser.cgi");
		for (@err) {
			print Yaffas::UI::all_error_box($_->[1]);
			my $tmp = $info{$_->[0]};
			my $uid = $_->[0];
			_edit_user($uid, $size, \@existing_groups, \@mail, $tmp );
		}

		print section_button($Cgi->submit($main::text{lbl_changeuser}));
		print $Cgi->end_form();
	}
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
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
